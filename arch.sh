#!/bin/bash
export ROOT="/dev/sda2"
export ESP="/dev/sda1"

timedatectl set-ntp true

pacman -S --noconfirm pacman-contrib reflector rsync

mkfs.btrfs -L ROOT -f $ROOT
mount -o rw,noatime,ssd,compress=zstd,space_cache $ROOT /mnt

mkfs.vfat -F32 -n "BOOP" $ESP
echo -e "t\n1\nef\nw" | fdisk /dev/sda
mkdir -pv /mnt/boot	
mount -t vfat -o noatime $ESP /mnt/boot

# get 32 servers synced in the last 48 hours, get the fastest 6
reflector -a 48 -l 32 -f 6 --verbose --sort rate --save /etc/pacman.d/mirrorlist

# set parallel downloads (line 37) to 64, and create a backup
sed -ibak -e '37s/.//' -e '37s/5/64/' /etc/pacman.conf

pacstrap /mnt linux linux-firmware base base-devel btrfs-progs 

# move back to backup 
mv /etc/pacman.confbak /etc/pacman.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
cp arch-post-install.sh /mnt/
genfstab -U /mnt >> /mnt/etc/fstab

bootctl install --esp-path=/mnt/boot
cat <<EOF > /mnt/boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options rw root=$ROOT quiet splash
EOF
echo -e "timeout 5\nconsole-mode max" > /mnt/boot/loader/loader.conf

arch-chroot /mnt cat <<EOF > /etc/systemd/network/eno2.network
[Match]
Name=eno2

[Network]
DHCP=yes
EOF 
arch-chroot /mnt systemctl enable systemd-networkd
arch-chroot /mnt passwd
echo -e "ready for first boot! :DD"
