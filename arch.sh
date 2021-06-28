#!/bin/bash

# partitioning simulator
fdisk -l
echo "drive: "
read drive
cfdisk $drive
echo "root partition: " 
read root
echo "efi partition: "
read esp
mkfs.btrfs -L arch -f $root
mkfs.vfat -n EFI -F 32 $esp
mount $root /mnt
mkdir /mnt/boot
mount $esp /mnt/boot

# enable parallel downloads (the stupid way)
sed -i '37s/.//' /etc/pacman.conf && sed -i '37s/5/10/' /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
pacstrap /mnt linux linux-firmware linux-headers base base-devel btrfs-progs
genfstab -U /mnt >> /mnt/etc/fstab

# name/hosts identification
echo $name > /etc/hostname
echo -e "127.0.0.1 localhost\n::1       localhost \n127.0.0.1 $hostname.localdomain $hostname" > /mnt/etc/hosts

# bootloader
arch-chroot /mnt bootctl install
echo -e "title   Arch Linux\nlinux   /vmlinuz-linux\ninitrd  /initramfs-linux.img\noptions rw root=$root" > /boot/loader/entries/arch.conf
echo -e "timeout 5\nconsole-mode max" > /boot/loader/loader.conf

# sudoers
sed -i '82s/. //' /mnt/etc/sudoers

# enable parallel downloads & multilib repo & refresh mirrors by speed
sed -i '33s/.//' /mnt/etc/pacman.conf && sed -i '37s/.//' /mnt/etc/pacman.conf && sed -i '93/.//' /mnt/etc/pacman.conf && sed -i '94/.//' /mnt/etc/pacman.conf
reflector --verbose --latest 5 --sort rate --save /mnt/etc/pacman.d/mirrorlist

sed '1,/^#part2$/d' arch.sh > /mnt/part2.sh
chmod +x /mnt/part2.sh
arch-chroot /mnt ./part2.sh
exit 

#part2

# locales
echo -e "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
sed -i '177s/.//' /mnt/etc/locale.gen
locale-gen

# timezone
timedatectl list-timezones
echo "timezone: "
read timezone
timedatectl set-ntp true
timedatectl set-timezone $timezone
hwclock --systohc

# shit
pacman ---noconfirm -Syu git wget neofetch networkmanager

echo "username: "
read user
useradd -m -G wheel -s /bin/bash $user
systemctl enable NetworkManager
echo "$user password: "
passwd $user 
echo "root password: "
passwd
rm /part2.sh
