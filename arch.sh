#!/bin/bash

echo "root: "
read ROOT
echo "esp: "
read ESP
echo "host: "
read HOST
echo "hostname: "
read NAME

if [[ $HOST = laptop ]] ; then	
	cryptsetup luksFormat $ROOT
	cryptsetup open $ROOT croot
	mkfs.ext4 /dev/mapper/croot
	mount /dev/mapper/croot /mnt

fi

if [[ $HOST = pc ]] ; then
	mkfs.ext4 $ROOT
	mkfs.vfat $ESP
	mount $ROOT /mnt


mkdir /mnt/boot
mount $ESP /mnt/boot
	
pacstrap /mnt linux linux-firmware linux-headers base base-devel intel-ucode 
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt bootctl install
ln -sf /mnt/usr/share/zoneinfo/Asia/Riyadh /mnt/etc/localtime
UUID = $(blkid -s UUID -o value $ROOT)
cp -v -r root/etc/sudoers.d /mnt/etc/
cp -v -r root/etc/systemd /mnt/etc/
cp -v -r root/etc/locale.conf /mnt/etc/ 
cp -v -r root/etc/locale.gen /mnt/etc/
cp -v -r root/boot /mnt/
echo $NAME > /mnt/etc/hostname
echo > /mnt/etc/issue
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $NAME.localdomain $NAME" >> /etc/hosts

if [[ $HOST = laptop ]] ; then
	echo "options rw cryptdevice=UUID=$UUID:croot root=/dev/mapper/croot" >> /mnt/boot/loader/entries/arch.conf
	pacstrap /mnt sof-firmware mesa xf86-video-intel alsa-ucm-conf networkmanager
	cp -v -r root/etc/modprobe.d /mnt/etc/
	cp -v -r root/etc/mkinitcpio.conf /mnt/etc/
fi

if [[ $HOST = pc ]] ; then
	echo "options rw root=UUID=$UUID" >> /mnt/boot/loader/entries/arch.conf
	pacstrap /mnt dhcpcd
fi

arch-chroot /mnt git nano \ 
		 acpid acpi \ 
		 alsa-utils pulseaudio pulseaudio-alsa \ 
		 xorg xorg-xinit xclip \ 
arch-chroot /mnt mkinitcpio -P linux
arch-chroot /mnt timedatectl set-ntp true && hwclock --systohc
arch-chroot /mnt useradd -m -s /bin/bash wael
arch-chroot /mnt locale-gen

passwd 
passwd wael

# 69 lines. nice.
