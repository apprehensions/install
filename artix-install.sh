#!/bin/bash
echo "rc? "
read rc
basestrap /mnt linux linux-firmware base base-devel btrfs-progs $rc elogind-$rc networkmanager networkmanager-$rc
mkdir /mnt/efi 
mount /dev/sda1 /mnt/efi
fstabgen -U /mnt >> /mnt/etc/fstab

# totally didnt steal
sed '1,/^#post$/d' arch.sh > /mnt/post.sh
chmod +x /mnt/post.sh
arch-chroot /mnt ./post.sh

#post
ln -sf /mnt/usr/share/zoneinfo/Asia/Riyadh /etc/localtime
timedatectl set-ntp true
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen
echo "KEYMAP=us" >> /etc/vconsole.conf
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts
echo "arch" > /etc/hostname
echo "wheel ALL=(ALL) ALL" >> /etc/sudoers.d/wheel
pacman -S --no confirm linux-headers xdg-user-dirs xdg-user-dirs \
                       nvidia nvidia-utils nvidia-settings xorg xorg-xinit xclip \
                       pulseaudio pulseaudio-alsa
useradd -m -G wheel -s /bin/bash wael
passwd
passwd wael
echo "umount -a and die"