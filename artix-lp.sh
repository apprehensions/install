#!/bin/bash
BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
HOSTNAME=yoga
HOST=lp-ao
ROOT="/dev/nvme0n1p2"
ESP="/dev/nvme0n1p1"
read PASS

mkfs.vfat -nESP -F32 $ESP
echo -n $PASS | cryptsetup -v luksFormat -s=512 $ROOT -d -
echo -n $PASS | cryptsetup open $ROOT kroot -d -
mkfs.btrfs -L kroot /dev/mapper/kroot
mount -o $BTRFS_OPTS /dev/mapper/kroot /mnt
mkdir /mnt/boot
mount -o rw,noatime $ESP /mnt/boot

sed -ibak -e '37s/.//' -e '37s/5/20/' /etc/pacman.conf
basestrap /mnt base base-devel linux linux-firmware linux-headers intel-ucode btrfs-progs runit elogind-runit iwd-runit dhcpcd-runit artix-archlinux-support grub os-prober efibootmgr
mv /etc/pacman.confbak /etc/pacman.conf
fstabgen -U /mnt >> /mnt/etc/fstab

sed '1,/^# - post$/d' $0 > /mnt/post.sh
cp ./modules /mnt/ -r
chmod a+x /mnt/post.sh
artix-chroot /mnt ./post.sh
umount -R /mnt
cryptsetup close kroot
exit

# - post

./modules/10-locale.sh
./modules/20-time.sh
./modules/21-iden.sh
./modules/30-pacman.sh
./modules/40-grub.sh
./modules/50-sv.sh
./modules/99-user.sh
rm /modules
rm /post.sh
