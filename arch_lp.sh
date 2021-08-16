#!/bin/bash
export BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
export ROOT="/dev/nvme0n1p2"
export ESP="/dev/nvme0n1p1"
export ESPDIR="/boot"
export HOSTNAME="yoga"
source ./mods

mkfs_part
mkfs_esp

sed -ibak -e '37s/.//' -e '37s/5/24/' /etc/pacman.conf
pacstrap /mnt base base-devel linux linux-firmware linux-headers intel-ucode btrfs-progs iwd
mv /etc/pacman.confbak /etc/pacman.conf
genfstab -U /mnt >> /mnt/etc/fstab

hosts_do
iwd_do

sed '1,/^# - post$/d' $0 > /mnt/post.sh
chmod a+x /mnt/post.sh
cp ./mods /mnt/
arch-chroot /mnt ./post.sh
umount -R /mnt
exit

# - post
source /mods

arch_needed
pacman_do
i915_do
systemd_boot_install
systemctl enable iwd
arch_make_me
arch_autologin
post_install_goodbye
