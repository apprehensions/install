#!/bin/bash

name="art"
read -p "change name different than art? [y/n]" answer
if [[ $answer = y ]] ; then
	echo "name: "
	read name
fi

basestrap /mnt linux linux-firmware linux-headers base base-devel openrc elogind-openrc btrfs-progs networkmanager networkmanager-openrc nvidia nvidia-utils nvidia-settings pulseaudio pulseaudio-alsa alsa-utils
fstabgen -U /mnt >> /mnt/etc/fstab

ln -sf /mnt/usr/share/zoneinfo/Asia/Riyadh /mnt/etc/localtime
artix-chroot /mnt hwclock --systohc

echo '"boot" "rw root=$part rootflags=subvol=@"' >> /mnt/boot/refind_linux.conf
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" >> /mnt/etc/locale.conf
artix-chroot /mnt locale-gen

echo "KEYMAP=us" >> /mnt/etc/vconsole.conf
echo "127.0.0.1 localhost" > /mnt/etc/hosts
echo "::1       localhost" >> /mnt/etc/hosts
echo "127.0.1.1 $name.localdomain $name" >> /mnt/etc/hosts
echo "$name" > /mnt/etc/hostname

artix-chroot /mnt useradd -m -G wheel -s /bin/bash wael
echo "wael ALL=(ALL) ALL" >> /mnt/etc/sudoers.d/wael
artix-chroot /mnt passwd wael
artix-chroot /mnt passwd
