#!/bin/bash
BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
HOSTNAME=br
ROOT="/dev/sda2"
BOOT="/dev/sda1"

mkfs.vfat -nGRUB -F32 $ESP
mkfs.btrfs -L arch -f $ROOT
mount -o $BTRFS_OPTS $ROOT /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snaps
btrfs subvolume set-default @
umount -R /mnt

mount -o $BTRFS_OPTS,subvol=@ $ROOT /mnt
mkdir -p /mnt/home
mkdir -p /mnt/.snaps
mkdir -p /mnt/efi
mount -o $BTRFS_OPTS,subvol=@home $ROOT /mnt/home
mount -o $BTRFS_OPTS,subvol=@snaps $ROOT /mnt/.snaps
mount -o rw,noatime $BOOT /mnt/efi

reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
sed -ibak -e '37s/.//' -e '37s/5/15/' /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
pacstrap /mnt linux linux-firmware linux-headers base base-devel btrfs-progs
mv /etc/pacman.confbak /etc/pacman.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
genfstab -U /mnt >> /mnt/etc/fstab

echo $HOSTNAME > /mnt/etc/hostname
echo -e "127.0.0.1 localhost\n::1       localhost \n127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" > /mnt/etc/hosts
mkdir /mnt/etc/systemd/system/getty@tty1.service.d
echo -e "[Service]\nExecStart=\nExecstart=-/usr/bin/agetty --noissue --autologin $NAME --noclear %I 38400 linux" > /mnt/etc/systemd/system/getty@tty1.service.d/override.conf
echo -e "[Match]\nName=eno1\n\n[Network]\nDHCP=yes" > /mnt/etc/systemd/network/lan.network
cp -r /etc/resolv.conf /mnt/etc/
echo LANG=en_US.UTF-8 > /mnt/etc/locale.conf
sed -i '177s/.//' /mnt/etc/locale.gen
sed -i '82s/. //' /mnt/etc/sudoers
sed -i -e '33s/.//' -e '37s/.//' -e '93,94s/.//' /mnt/etc/pacman.conf
sed '1,/^#part2$/d' wael.sh > /mnt/part2.sh
chmod +x /mnt/part2.sh
arch-chroot /mnt ./part2.sh
exit 

#part2
locale-gen
timedatectl set-ntp true
ln -sf /usr/share/zoneinfo/Asia/Riyadh /etc/localtime
hwclock --systohc
pacman --noconfirm -Syu git wget neofetch openssh zsh zsh-syntax-highlighting exa
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id='Arch Linux'
grub-mkconfig -o /boot/grub/grub.cfg
git clone https://aur.archlinux.org/paru.git /usr/src/paru && chmod 777 /usr/src/paru
systemctl enable systemd-networkd
systemctl enable fstrim.timer
systemctl enable sshd
useradd -m -G wheel -s /bin/zsh wael
passwd && passwd wael
