#!/bin/bash

echo "root: "
read ROOT
echo "esp: "
read ESP
cryptsetup luksFormat $ROOT
cryptsetup open $ROOT croot
mkfs.ext4 /dev/mapper/croot
mount /dev/mapper/croot /mnt
mkdir /mnt/boot
mount $ESP /mnt/boot

pacstrap /mnt linux linux-firmware linux-headers base intel-ucode networkmanager intel-media-driver base-devel git sof-firmware acpid alsa-ucm-conf alsa-utils pulseaudio pulseaudio-alsa mesa xf86-video-intel
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt bootctl install
UUID = $(blkid -s UUID -o value $ROOT)
echo "options rw cryptdevice=UUID=$UUID:croot root=/dev/mapper/croot" >> /mnt/boot/loader/entries/arch.conf
ln -sf /mnt/usr/share/zoneinfo/Asia/Riyadh /mnt/etc/localtime
arch-chroot /mnt timedatectl set-ntp true && hwclock --systohc
arch-chroot /mnt useradd -m -s /bin/bash wael
DIR = $(pwd)
cp -v $DIR/root/etc /mnt/etc
cp -v $DIR/root/boot /mnt/boot
arch-chroot /mnt locale-gen

