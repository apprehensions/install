#!/bin/bash
set -x
echo "drive: "
read drive
cfdisk $drive
echo "partition: "
read part
mkfs.btrfs $part -f
mount $part /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt
mount -o relatime,compress=zstd,space_cache,discard=async,subvol=@ $part /mnt
mkdir /mnt/home
mount -o relatime,compress=zstd,space_cache,discard=async,subvol=@home $part /mnt/home

basestrap /mnt linux linux-firmware linux-headers base base-devel openrc elogind-openrc btrfs-progs networkmanager networkmanager-openrc nvidia nvidia-utils nvidia-settings
fstabgen -U /mnt >> /mnt/etc/fstab

ln -sf /mnt/usr/share/zoneinfo/Asia/Riyadh /mnt/etc/localtime
artix-chroot /mnt hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" >> /mnt/etc/locale.conf
echo "KEYMAP=us" >> /mnt/etc/vconsole.conf
echo "127.0.0.1 localhost" > /mnt/etc/hosts
echo "::1       localhost" >> /mnt/etc/hosts
echo "127.0.1.1 artix.localdomain artix" >> /mnt/etc/hosts
echo "artix" > /mnt/etc/hostname
echo "wael ALL=(ALL) ALL" >> /mnt/etc/sudoers.d/wael

artix-chroot /mnt locale-gen
artix-chroot /mnt useradd -m -s /bin/bash wael
artix-chroot /mnt passwd wael
artix-chroot /mnt passwd
