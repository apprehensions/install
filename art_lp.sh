#!/bin/bash
export BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
export ROOT="/dev/nvme0n1p2"
export ESP="/dev/nvme0n1p1"
export HOSTNAME=yoga
source ./mods

mkfs_part
mkdir /mnt/efi
mount -o rw,noatime $ESP /mnt/efi

sed -ibak -e '37s/.//' -e '37s/5/20/' /etc/pacman.conf
basestrap /mnt base base-devel linux linux-firmware linux-headers intel-ucode btrfs-progs openrc elogind-openrc iwd-openrc grub os-prober efibootmgr
mv /etc/pacman.confbak /etc/pacman.conf
fstabgen -U /mnt >> /mnt/etc/fstab

hosts_do
resolv_do

sed '1,/^# - post$/d' $0 > /mnt/post.sh
chmod a+x /mnt/post.sh
cp ./mods /mnt/
artix-chroot /mnt ./post.sh
umount -R /mnt
exit

# - post
source /mods

a_needed
pacman_do
artix_chroot_support_do
i915_do
grub_install
a_make_me
rc-update add iwd default
rm /mods
rm /post.sh
