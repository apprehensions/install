#!/bin/bash
# https://github.com/Bugswriter/arch-linux-magic/blob/master/arch_install.sh
# https://gitlab.com/eflinux/arch-basic/-/blob/master/install-uefi.sh
# I DONT KNOW HOW TO SCTI PT -LKE S HEL PEM M
name=br
echo "root: "
read root
echo "esp: "
read esp
echo "data: "
read data

mkfs.btrfs -f $root
mkfs.vfat -F 32 $esp
mount $root /mnt
btrfs subvolume create /mnt/@
btrfs subvolume set-default /mnt/@
umount -R /mnt
mount -o compress=zstd,subvol=@ $root /mnt
mkdir /mnt/boot
mount $esp /mnt/boot
mkdir /mnt/mnt
mount $data /mnt

pacstrap /mnt linux linux-firmware linux-headers base base-devel intel-ucode btrfs-progs nvidia 
genfstab -U /mnt >> /mnt/etc/fstab
cp -v -r root/etc /mnt
cp -v -r root/boot /mnt
echo $name > /mnt/etc/hostname
echo "127.0.0.1 localhost" > /mnt/etc/hosts
echo "::1       localhost" >> /mnt/etc/hosts
echo "127.0.1.1 $name.localdomain $name" >> /mnt/etc/hosts
echo "wael ALL=(ALL) ALL" > /mnt/etc/sudoers.d/wael
echo "LANG=en_us.UTF-8" > /mnt/etc/locale.conf
sed -i '177s/.//' /mnt/etc/locale.gen
echo "options rw root=$root rootflags=subvol=@" >> /mnt/boot/loader/entries/arch.conf
sed '1,/^#part2$/d' pc.sh > /mnt/pc-p2.sh
chmod +x /mnt/part2.sh
arch-chroot /mnt ./part2.sh
exit 

#part2
bootctl install
timedatectl set-ntp true
timedatectl set-timezone Asia/Riyadh
pacman -S git wget zsh
useradd -m -s /bin/zsh wael
locale-gen
git clone https://aur.archlinux.org/paru.git /usr/src/paru
systemctl enable systemd-networkd
systemctl enable reflector.timer
systemctl enable fstrim.timer  
systemctl enable sshd
passwd wael && passwd

