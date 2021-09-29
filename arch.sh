#!/bin/bash
export ROOT="/dev/sda2"
export ESP="/dev/sda1"

mkfs.btrfs -L root -f $ROOT
mount -o rw,noatime,ssd,compress=zstd,space_cache $ROOT /mnt

mkfs.vfat -nBOOP -F32 $ESP
# fdisk, drive type, partition 1, write
echo -e "t\n1\n1\nw" | fdisk /dev/sda
mkdir -pv /mnt/boot	
mount -o rw,noatime $ESP /mnt/boot

# create a mirrorlist of the latest 5 and fastest
reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

# set parallel downloads (line 37) to 50, and create a backup
sed -ibak -e '37s/.//' -e '37s/5/50/' /etc/pacman.conf

pacstrap /mnt linux linux-firmware linux-headers intel-ucode \
              base base-devel btrfs-progs

# move back to backup 
mv /etc/pacman.confbak /etc/pacman.conf

cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
genfstab -U /mnt >> /mnt/etc/fstab

timedatectl set-ntp true

echo br > /mnt/etc/hostname

sed '1,/^# - post$/d' $0 > /mnt/post-install.sh
chmod a+x /mnt/post-install.sh
arch-chroot /mnt ./post-install.sh
rm /mnt/post-install.sh
echo "your install is done now go outside"
umount -R /mnt
exit

# - post
echo "LANG=en_US.UTF-8" > /etc/locale.conf
cat <<EOF > /etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
EOF
echo "FONT=ter-v18n" > /etc/vconsole.conf
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
ln -sf /usr/share/zoneinfo/Asia/Riyadh /etc/localtime
hwclock --systohc

# colors, paralleldownloads = 12, multilib
sed -i '33s/.//' /etc/pacman.conf
sed -i -e '37s/.//' -e '37s/5/12/' /etc/pacman.conf
sed -i '93,94s/.//' /etc/pacman.conf
pacman --noconfirm -Sy zsh terminus-font  \
                       nvidia-dkms nvidia-utils nvidia-settings 

cat <<EOF > /etc/systemd/network/lan.network
[Match]
Name=eno2

[Network]
DHCP=yes
EOF 
systemctl enable systemd-networkd

mkdir -pv /etc/iwd
cat <<EOF > /etc/iwd/main.conf
[General]
UseDefaultInterface=true
EOF
systemctl enable iwd

echo "blacklist i2c_nvidia_gpu" > /etc/modprobe.d/blacklist.conf 
echo "blacklist iTCO_wdt" >> /etc/modprobe.d/blacklist.conf 
echo "options nvidia-drm modeset=1" > /etc/modprobe.d/nvidia-drm.conf 
sed -i '7s/()/(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
mkinitcpio -P

bootctl install
cat <<EOF > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options rw root=$ROOT quiet splash
EOF
echo -e "timeout 5\nconsole-mode max" > /boot/loader/loader.conf

sed -i '82s/. //' /etc/sudoers
useradd -mG wheel,audio,video,kvm,storage -s /bin/zsh wael
passwd && passwd wael 
mkdir /etc/systemd/system/getty@tty1.service.d
cat <<EOF > /etc/systemd/system/getty@tty1.service.d/override.conf 
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --noissue --autologin wael --noclear %I \$TERM"
EOF
