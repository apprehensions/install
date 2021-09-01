#!/bin/bash
export BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
export ROOT="/dev/nvme0n1p2"
export ESP="/dev/nvme0n1p1"
export ESPDIR="/boot"
export HOSTNAME="br"
source ./mods

mkfs_root
mkfs_esp

reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
sed -ibak -e '37s/.//' -e '37s/5/24/' /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
pacstrap /mnt linux linux-firmware linux-headers base base-devel btrfs-progs nvidia nvidia-settings
mv /etc/pacman.confbak /etc/pacman.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
genfstab -U /mnt >> /mnt/etc/fstab

sed '1,/^# - post$/d' $0 > /mnt/post.sh
chmod a+x /mnt/post.sh
cp ./mods /mnt/
arch-chroot /mnt ./post.sh
umount -R /mnt
exit

# - post
source /mods

clear && arch_needed

# pkg
clear && pacman_do
clear && arch_reflector

# bootloader
clear && systemd_boot_install

# host related
blacklist_pc

# service
clear && echo -e "[Match]\nName=eno2\n\n[Network]\nDHCP=yes" > /etc/systemd/network/lan.network
systemctl enable systemd-networkd

# user
clear && arch_useradd
systemd_autologin

clear && post_install_goodbye
