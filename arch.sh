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

pacstrap /mnt linux linux-firmware linux-headers base base-devel intel-ucode 
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt bootctl install
ln -sf /mnt/usr/share/zoneinfo/Asia/Riyadh /mnt/etc/localtime
arch-chroot /mnt timedatectl set-ntp true && hwclock --systohc
arch-chroot /mnt useradd -m -s /bin/bash wael
cp -v -r root/etc /mnt/
cp -v -r root/boot /mnt/
UUID = $(blkid -s UUID -o value $ROOT)
echo "options rw cryptdevice=UUID=$UUID:croot root=/dev/mapper/croot" >> /mnt/boot/loader/entries/arch.conf
arch-chroot /mnt locale-gen

arch-chroot /mnt networkmanager git nano \ # tools
		 acpid acpi sof-firmware mesa xf86-video-intel \ # drivers (acpi,audio,graphics)
		 alsa-utils alsa-ucm-conf pulseaudio pulseaudio-alsa \ # audio
		 xorg xorg-xinit xclip \ # xorg

arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt mkinitcpio -P linux
