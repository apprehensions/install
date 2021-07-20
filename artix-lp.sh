#!/bin/bash
BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
HOSTNAME=yoga
HOST=lp
ROOT="/dev/nvme0n1p2"
ESP="/dev/nvme0n1p1"
read PASS
mkfs.vfat -nESP -F32 $ESP
echo $PASS | cryptsetup -v luksFormat -s=512 $ROOT -d -
echo $PASS | cryptsetup open $ROOT kroot -d -
mkfs.btrfs -L kroot /dev/mapper/kroot
mount -o $BTRFS_OPTS /dev/mapper/kroot /mnt
mkdir /mnt/boot
mount -o rw,noatime $ESP /mnt/boot

sed -ibak -e '37s/.//' -e '37s/5/20/' /etc/pacman.conf
basestrap /mnt base base-devel linux linux-firmware linux-headers intel-ucode btrfs-progs runit elogind-runit iwd-runit dhcpcd-runit artix-archlinux-support
mv /etc/pacman.confbak /etc/pacman.conf
fstabgen -U /mnt >> /mnt/etc/fstab

sed '1,/^# - post$/d' $0 > /mnt/post.sh
cp ./modules /mnt/ -r
chmod a+x /mnt/post.sh
artix-chroot /mnt ./post.sh
umount -R /mnt
exit

# - post

./modules/locale.sh
./modules/time.sh
./modules/pacman.sh
pacman --noconfirm -Sy grub os-prober efibootmgr wget git zsh exa
git clone https://aur.archlinux.org/paru.git /usr/src/paru && chmod 777 /usr/src/paru
echo $HOSTNAME > /etc/hostname
ln -sv /etc/runit/sv/dhcpcd /etc/runit/runsvdir/default/
ln -sv /etc/runit/sv/dbus /etc/runit/runsvdir/default/
ln -sv /etc/runit/sv/sshd /etc/runit/runsvdir/default/
ln -sv /etc/runit/sv/iwd /etc/runit/runsvdir/default/
./modules/grub.sh
sed -i "/GETTY_ARGS=/s/\"$/ --autologin wael&/" /etc/runit/sv/agetty-tty1/conf
sed -i '82s/. //' /etc/sudoers
useradd -mG wheel,audio,video,kvm,storage -s /bin/zsh wael
passwd && passwd wael
