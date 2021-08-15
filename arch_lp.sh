#!/bin/bash
export BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
export ROOT="/dev/nvme0n1p2"
export ESP="/dev/nvme0n1p1"
export HOSTNAME=yoga
source ./mods

mkfs_part
mkdir /mnt/efi
mount -o rw,noatime $ESP /mnt/efi

sed -ibak -e '37s/.//' -e '37s/5/24/' /etc/pacman.conf
basestrap /mnt base base-devel linux linux-firmware linux-headers intel-ucode btrfs-progs iwd
mv /etc/pacman.confbak /etc/pacman.conf
genfstab -U /mnt >> /mnt/etc/fstab

sed '1,/^# - post$/d' $0 > /mnt/post.sh
cp ./modules /mnt/ -r
chmod a+x /mnt/post.sh
artix-chroot /mnt ./post.sh
umount -R /mnt
exit

# - post

set -x
./modules/10-needed.sh
./modules/30-pkg.sh
./modules/31-vid.sh
./modules/40-boot.sh
./modules/50-net.sh
./modules/99-user.sh
systemctl enable iwd
rm /modules -rf
rm /post.sh
