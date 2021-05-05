#!/bin/bash
read -p "partition disk? [y/n]" answer

if [[ $answer = y ]] ; then
	echo "disk: "
	read disk
	cfdisk $disk
fi

name="arch"
read -p "change name different than arch? [y/n]" answer
if [[ $answer = y ]] ; then
	echo "name: "
	read name
fi
	
echo "partition: "
read part
mkfs.btrfs $part -f
mount $part /mnt

#meant for ssd only
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt
mount -o relatime,compress=zstd,space_cache,discard=async,subvol=@ $part /mnt
mkdir /mnt/{efi,home}
mount -o relatime,compress=zstd,space_cache,discard=async,subvol=@home $part /mnt/home
mount /dev/sda1 /mnt/efi

pacstrap /mnt linux linux-firmware linux-headers base base-devel btrfs-progs
genfstab -U /mnt >> /mnt/etc/fstab

ln -sf /mnt/usr/share/zoneinfo/Asia/Riyadh /mnt/etc/localtime
echo ""boot" "rw root=$part rootflags=subvol=@""
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" >> /mnt/etc/locale.conf
echo "KEYMAP=us" >> /mnt/etc/vconsole.conf
echo "127.0.0.1 localhost" > /mnt/etc/hosts
echo "::1       localhost" >> /mnt/etc/hosts
echo "127.0.1.1 $name.localdomain $name" >> /mnt/etc/hosts
echo "$name" > /mnt/etc/hostname
echo "wael ALL=(ALL) ALL" >> /mnt/etc/sudoers.d/wael

# i use arch-chroot due to complications
arch-chroot /mnt locale-gen
arch-chroot /mnt timedatectl set-ntp true && hwclock --systohc
arch-chroot /mnt pacman -Syu xdg-user-dirs xdg-user-dirs networkmanager nvidia nvidia-utils nvidia-settings xorg xorg-xinit xclip pulseaudio pulseaudio-alsa
arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt useradd -m -G wheel -s /bin/bash wael
arch-chroot /mnt passwd wael
arch-chroot /mnt passwd
