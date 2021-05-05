#!/bin/bash

name="arch"
read -p "change name different than arch? [y/n]" answer
if [[ $answer = y ]] ; then
	echo "name: "
	read name
fi

pacstrap /mnt linux linux-firmware linux-headers base base-devel btrfs-progs
genfstab -U /mnt >> /mnt/etc/fstab

ln -sf /mnt/usr/share/zoneinfo/Asia/Riyadh /mnt/etc/localtime
arch-chroot /mnt timedatectl set-ntp true && hwclock --systohc

echo '"boot" "rw root=$part rootflags=subvol=@"' >> /mnt/boot/refind_linux.conf
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" >> /mnt/etc/locale.conf
arch-chroot /mnt locale-gen

echo "KEYMAP=us" >> /mnt/etc/vconsole.conf
echo "127.0.0.1 localhost" > /mnt/etc/hosts
echo "::1       localhost" >> /mnt/etc/hosts
echo "127.0.1.1 $name.localdomain $name" >> /mnt/etc/hosts
echo "$name" > /mnt/etc/hostname

arch-chroot /mnt useradd -m -G wheel -s /bin/bash wael
echo "wael ALL=(ALL) ALL" >> /mnt/etc/sudoers.d/wael
arch-chroot /mnt passwd wael
arch-chroot /mnt passwd

# i use arch-chroot due to complications
arch-chroot /mnt pacman -Syu xdg-user-dirs xdg-user-dirs networkmanager nvidia nvidia-utils nvidia-settings xorg xorg-xinit xclip pulseaudio pulseaudio-alsa
arch-chroot /mnt systemctl enable NetworkManager

