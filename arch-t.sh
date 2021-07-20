#!/bin/bash

# partitioning simulator
echo "$(tput bold)root partition: $(tput sgr0)" 
read root
echo "$(tput bold)efi partition: $(tput sgr0)"
read esp
mkfs.btrfs -L arch -f $root
mkfs.vfat -nEFI -F 32 $esp
mount $root /mnt
mkdir /mnt/boot
mount $esp /mnt/boot

# enable parallel downloads (the stupid way)
sed -ibak -e '37s/.//' -e '37s/5/10/' /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
pacstrap /mnt linux linux-firmware linux-headers base base-devel btrfs-progs
cp /etc/pacman.confbak /etc/pacman.conf
genfstab -U /mnt >> /mnt/etc/fstab

# name/hosts identification
echo -e "\n$(tput bold)hostname: $(tput sgr0)"
read name
echo $name > /mnt/etc/hostname
echo -e "127.0.0.1 localhost\n::1       localhost \n127.0.1.1 $name.localdomain $name" > /mnt/etc/hosts

# locales
echo -e "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
sed -i '177s/.//' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

# timezone
echo "$(tput bold)timezone: $(tput sgr0)"
read timezone
arch-chroot /mnt ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
arch-chroot /mnt hwclock --systohc

# bootloader (systemd-boot)
arch-chroot /mnt bootctl install
echo -e "title   Arch Linux\nlinux   /vmlinuz-linux\ninitrd  /initramfs-linux.img\noptions rw root=$root" > /mnt/boot/loader/entries/arch.conf
echo -e "timeout 5\nconsole-mode max" > /mnt/boot/loader/loader.conf

# enable parallel downloads & multilib repo (the stupid way) & refresh mirrors 
sed -i -e '33s/.//' -e '37s/.//' -e '93,94s/.//' /mnt/etc/pacman.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/

# shit
arch-chroot /mnt pacman --noconfirm -Syu git wget neofetch networkmanager
arch-chroot /mnt systemctl enable NetworkManager

# user 
sed -i '82s/. //' /mnt/etc/sudoers
echo -e "\n$(tput bold)username: $(tput sgr0)"
read user
arch-chroot /mnt useradd -m -G wheel -s /bin/bash $user
echo -e "\n$(tput bold)$user password: $(tput sgr0)"
arch-chroot /mnt passwd $user 
echo -e "\n$(tput bold)root password: $(tput sgr0)"
arch-chroot /mnt passwd

arch-chroot /mnt
umount -R /mnt
reboot