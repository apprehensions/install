#!/bin/bash
export BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
export ROOT="/dev/nvme0n1p2"
export ESP="/dev/nvme0n1p1"
export ESPDIR="/boot"
export HOSTNAME=yoga
source ./mods

mkfs_part
mkfs_esp

sed -ibak -e '37s/.//' -e '37s/5/20/' /etc/pacman.conf
basestrap /mnt base base-devel linux linux-firmware linux-headers intel-ucode btrfs-progs openrc elogind-openrc iwd-openrc grub os-prober efibootmgr
mv /etc/pacman.confbak /etc/pacman.conf
fstabgen -U /mnt >> /mnt/etc/fstab

hosts_do
iwd_do

sed '1,/^# - post$/d' $0 > /mnt/post.sh
chmod a+x /mnt/post.sh
cp ./mods /mnt/
artix-chroot /mnt ./post.sh
umount -R /mnt
exit

# - post
source /mods

arch_needed
pacman_do
artix_archlinux_support_do
i915_do
grub_install
rc-update add iwd default
arch_make_me
arch_autologin
post_install_goodbye
