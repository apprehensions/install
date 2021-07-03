#!/bin/bash

# partitioning simulator
echo "$(tput bold)root partition: $(tput sgr0)" 
read root
echo "$(tput bold)efi partition: $(tput sgr0)"
read esp
mkfs.btrfs -L artix -f $root
mkfs.vfat -n EFI -F 32 $esp
mount $root /mnt
mkdir /mnt/boot
mount $esp /mnt/boot

# enable parallel downloads (the stupid way)
sed -ibak -e '37s/.//' -e '37s/5/10/' /etc/pacman.conf
basestrap -i /mnt base base-devel linux linux-firmware btrfs-progs
cp /etc/pacman.confbak /etc/pacman.conf
fstabgen -U /mnt >> /mnt/etc/fstab

# name/hosts identification
echo -e "\n$(tput bold)hostname: $(tput sgr0)"
read name
echo $name > /mnt/etc/hostname
echo -e "127.0.0.1 localhost\n::1       localhost \n127.0.1.1 $name.localdomain $name" > /mnt/etc/hosts

# locales
echo -e "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
sed -i '177s/.//' /mnt/etc/locale.gen
artix-chroot /mnt locale-gen

# bootloader (grub)
artix-chroot pacman -S grub os-prober efibootmgr
artix-chroot grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub (for UEFI systems)
artix-chroot grub-mkconfig -o /boot/grub/grub.cfg

# enable group wheel to access sudo
sed -i '82s/. //' /mnt/etc/sudoers

# timezone
echo "$(tput bold)timezone: $(tput sgr0)"
read timezone
ln -sf /mnt/usr/share/zoneinfo/$timezone /mnt/etc/localtime
artix-chroot /mnt hwclock --systohc

# shit
artix-chroot /mnt pacman --noconfirm -Syu git wget neofetch networkmanager
artix-chroot /mnt systemctl enable NetworkManager

# enable parallel downloads & multilib repo (the stupid way)
sed -i -e '33s/.//' -e '37s/.//' -e '93,94s/.//' /mnt/etc/pacman.conf

# user password/creation
echo -e "\n$(tput bold)username: $(tput sgr0)"
read user
artix-chroot /mnt useradd -m -G wheel -s /bin/bash $user
echo -e "\n$(tput bold)$user password: $(tput sgr0)"
artix-chroot /mnt passwd $user 
echo -e "\n$(tput bold)root password: $(tput sgr0)"
artix-chroot /mnt passwd

umount -R /mnt
reboot
