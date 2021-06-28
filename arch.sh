#!/bin/bash

# partitioning simulator
fdisk -l
echo "$(tput bold)drive: $(tput sgr0)"
read drive
cfdisk $drive
echo "$(tput bold)root partition: $(tput sgr0)" 
read root
echo "$(tput bold)efi partition: $(tput sgr0)"
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
echo "$(tput bold)hostname: $(tput sgr0)"
read hostname
echo $name > /etc/hostname
echo -e "127.0.0.1 localhost\n::1       localhost \n127.0.1.1 $hostname.localdomain $hostname" > /mnt/etc/hosts

# bootloader
arch-chroot /mnt bootctl install
echo -e "title   Arch Linux\nlinux   /vmlinuz-linux\ninitrd  /initramfs-linux.img\noptions rw root=$root" > /mnt/boot/loader/entries/arch.conf
echo -e "timeout 5\nconsole-mode max" > /mnt/boot/loader/loader.conf

# sudoers
sed -i '82s/. //' /mnt/etc/sudoers

# enable parallel downloads & multilib repo & refresh mirrors by speed
sed -i '33s/.//' /mnt/etc/pacman.conf && sed -i '37s/.//' /mnt/etc/pacman.conf && sed -i '93/.//' /mnt/etc/pacman.conf && sed -i '94/.//' /mnt/etc/pacman.conf
reflector --verbose --latest 5 --sort rate --save /mnt/etc/pacman.d/mirrorlist

# locales
echo -e "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
sed -i '177s/.//' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

# timezone
timedatectl list-timezones
echo "timezone: "
read timezone
arch-chroot /mnt timedatectl set-ntp true
arch-chroot /mnt timedatectl set-timezone $timezone
hwclock --systohc

# shit
arch-chroot /mnt pacman --noconfirm -Syu git wget neofetch networkmanager
arch-chroot /mnt systemctl enable NetworkManager

# user password/creation
echo -e "\n$(tput bold)username: $(tput sgr0)"
read user
arch-chroot /mnt useradd -m -G wheel -s /bin/bash $user
echo -e "\n$(tput bold)$user password: $(tput sgr0)"
arch-chroot /mnt passwd $user 
echo -e "\n$(tput bold)root password: $(tput sgr0)"
arch-chroot /mnt passwd

umount -R /mnt
# 69 lines. nice.
