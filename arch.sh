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

pacstrap /mnt linux linux-firmware linux-headers base intel-ucode networkmanager intel-media-driver base-devel git sof-firmware acpid alsa-ucm-conf alsa-utils mesa xf86-video-intel
genfstab -U /mnt >> /mnt/etc/fstab

# bootloader
arch-chroot /mnt bootctl install
UUID = $(blkid -s UUID -o value $ROOT)
echo "options rw cryptdevice=UUID=$UUID:croot root=/dev/mapper/croot" >> /mnt/boot/loader/entries/arch.conf
arch-chroot locale-gen
# time
ln -sf /mnt/usr/share/zoneinfo/Asia/Riyadh /mnt/etc/localtime
arch-chroot /mnt timedatectl set-ntp true && hwclock --systohc
# creating me :3
arch-chroot /mnt useradd -m -s /bin/bash wael


