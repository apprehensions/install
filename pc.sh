#!/bin/bash
# these are literally made for me, please never use this unless you are wael

echo "root: "
read root
echo "host: "
read host
echo "hostname: "
read name
echo "esp: "
read esp
mkfs.btrfs -f $root
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount -R /mnt
mount -o compress=zstd,subvol=/@ /dev/mapper/croot /mnt
mkdir /mnt/home
mount -o compress=zstd,subvol=/@home /dev/mapper/croot /mnt
mkdir /mnt/boot
mount $esp /mnt/boot

pacstrap /mnt linux linux-firmware linux-headers base base-devel intel-ucode btrfs-progs nvidia
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt bootctl install
cp -v -r root/etc/systemd /mnt/etc/
echo $name > /mnt/etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $name.localdomain $name" >> /etc/hosts
echo "wael ALL=(ALL) ALL" > /etc/sudoers.d/wael
echo "LANG=en_us.UTF-8" > /etc/locale.conf
echo "en_us.UTF-8 UTF-8" > /etc/locale.gen
echo "title   Arch Linux"
echo "linux   /vmlinuz-linux" >> /mnt/boot/loader/entries/arch.conf
echo "initrd  /intel-ucode.img" >> /mnt/boot/loader/entries/arch.conf
echo "initrd  /initramfs-linux.img" > /mnt/boot/loader/entries/arch.conf
echo "options rw root=$root rootflags=subvol=@" >> /mnt/boot/loader/entries/arch.conf
arch-chroot /mnt timedatectl set-ntp true
arch-chroot /mnt timedatectl set-timezone Asia/Riyadh
arch-chroot /mnt useradd -m -s /bin/zsh wael
arch-chroot /mnt locale-gen
arch-chroot /mnt passwd wael
arch-chroot /mnt passwd
# https://github.com/Bugswriter/arch-linux-magic/blob/master/arch_install.sh
