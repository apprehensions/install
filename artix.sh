#!/bin/bash
BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
ROOT="/dev/sda2"
ESP="/dev/sda1"
HOSTNAME="br"

mkfs.vfat -nBOOT -F32 $ESP
mkfs.btrfs -L arch -f $ROOT
mount -o $BTRFS_OPTS $ROOT /mnt
btrfs subvolume create /mnt/@
btrfs subvolume set-default /mnt/@
umount -R /mnt

mount -o $BTRFS_OPTS,subvol=@ $ROOT /mnt
mkdir /mnt/efi
mount -o rw,noatime $ESP /mnt/efi

reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
sed -ibak -e '37s/.//' -e '37s/5/20/' /etc/pacman.conf
basestrap /mnt base base-devel linux linux-firmware linux-headers intel-ucode nvidia nvidia-settings btrfs-progs runit elogind-runit dhcpcd-runit
mv /etc/pacman.confbak /etc/pacman.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
fstabgen -U /mnt >> /mnt/etc/fstab

sed '1,/^# - post$/d' $0 > /mnt/post.sh
chmod a+x /mnt/post.sh
arch-chroot /mnt ./post.sh
umount -R /mnt
reboot

# - post

# - locale
echo "LANG=en_US.UTF-8" > /etc/locale.conf
sed -i '177s/.//' /etc/locale.gen
locale-gen

# - time
ln -sf /mnt/usr/share/zoneinfo/Asia/Riyadh /etc/localtime
hwclock --systohc

# - pacman shenanigans [multilib,paralell,color] & AUR helper
sed -i -e '33s/.//' -e '37s/.//' -e '93,94s/.//' /etc/pacman.conf
pacman --noconfirm -Sy grub os-prober efibootmgr wget git zsh zsh-syntax-highlighting
git clone https://aur.archlinux.org/paru.git /usr/src/paru && chmod 777 /usr/src/paru

# - network
echo $HOSTNAME > /etc/hostname
echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > /etc/resolv.conf
echo -e "127.0.0.1 localhost\n::1       localhost \n127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" > /etc/hosts
ln -s /etc/runit/sv/dhcpcd /etc/runit/runsvdir/default/
ln -s /etc/runit/sv/sshd /etc/runit/runsvdir/default/

# - bootloader [GRUB, will change later]
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id='Artix Linux'
grub-mkconfig -o /boot/grub/grub.cfg

# - autologin tty1 & sudoers & make me :3
sed -i "/GETTY_ARGS=/s/\"$/ --autologin wael&/" /etc/runit/sv/agetty-tty1/conf
sed -i '82s/. //' /mnt/etc/sudoers
useradd -mG wheel -s /bin/zsh wael
passwd && passwd wael
