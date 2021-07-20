#!/bin/bash
BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
HOSTNAME=yoga
ROOT="/dev/nvme0n1p2"
ESP="/dev/nvme0n1p1"

mkfs.vfat -nESP -F32 $ESP
cryptsetup -v luksFormat -s=512 $ROOT
cryptsetup open $ROOT kroot
mkfs.btrfs -L artix -f /dev/mapper/kroot
mount -o $BTRFS_OPTS $ROOT /mnt
mkdir /mnt/boot
mount -o rw,noatime $ESP /mnt/boot

sed -ibak -e '37s/.//' -e '37s/5/20/' /etc/pacman.conf
basestrap /mnt base base-devel linux linux-firmware linux-headers intel-ucode btrfs-progs runit elogind-runit iwd-runit dhcpcd-runit
mv /etc/pacman.confbak /etc/pacman.conf
fstabgen -U /mnt >> /mnt/etc/fstab

sed '1,/^# - post$/d' $0 > /mnt/post.sh
chmod a+x /mnt/post.sh
artix-chroot /mnt ./post.sh
umount -R /mnt
exit

# - post

echo "LANG=en_US.UTF-8" > /etc/locale.conf
sed -i '177s/.//' /etc/locale.gen
locale-gen
ln -sf /usr/share/zoneinfo/Asia/Riyadh /etc/localtime
hwclock --systohc

sed -i -e '33s/.//' -e '37s/.//' -e '93,94s/.//' /etc/pacman.conf
pacman --noconfirm -Sy grub os-prober efibootmgr wget git zsh exa
git clone https://aur.archlinux.org/paru.git /usr/src/paru && chmod 777 /usr/src/paru

echo $HOSTNAME > /etc/hostname
echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > /etc/resolv.conf

ln -sv /etc/runit/sv/dhcpcd /etc/runit/runsvdir/default/
ln -s /etc/runit/sv/dbus /etc/runit/runsvdir/default/
ln -sv /etc/runit/sv/sshd /etc/runit/runsvdir/default/
ln -sv /etc/runit/sv/iwd /etc/runit/runsvdir/default/

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id='Artix Linux'
grub-mkconfig -o /boot/grub/grub.cfg

sed -i "/GETTY_ARGS=/s/\"$/ --autologin wael&/" /etc/runit/sv/agetty-tty1/conf
sed -i '82s/. //' /etc/sudoers
useradd -mG wheel,audio,video,kvm,storage,socklog -s /bin/zsh wael
passwd && passwd wael
