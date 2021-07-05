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
mkdir /mnt/boot
mount -o rw,noatime $ESP /mnt/boot

timedatectl set-ntp true
reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
sed -ibak -e '37s/.//' -e '37s/5/20/' /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
pacstrap /mnt linux linux-firmware linux-headers base base-devel btrfs-progs nvidia nvidia-settings
mv /etc/pacman.confbak /etc/pacman.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
genfstab -U /mnt >> /mnt/etc/fstab

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
ln -sf /usr/share/zoneinfo/Asia/Riyadh /etc/localtime
hwclock --systohc

# - pacman shenanigans [multilib,paralell,color] & AUR helper
sed -i -e '33s/.//' -e '37s/.//' -e '37s/5/20/' -e '93,94s/.//' /etc/pacman.conf
pacman --noconfirm -Syu git wget neofetch openssh zsh zsh-syntax-highlighting exa pipewire pipewire-pulse pulsemixer pipewire-alsa
git clone https://aur.archlinux.org/paru.git /usr/src/paru && chmod 777 /usr/src/paru

# - network
echo $HOSTNAME > /etc/hostname
echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > /etc/resolv.conf
echo -e "127.0.0.1 localhost\n::1       localhost \n127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" > /etc/hosts
echo -e "[Match]\nName=eno1\n\n[Network]\nDHCP=yes" > /etc/systemd/network/lan.network
systemctl enable systemd-networkd
systemctl enable sshd

# - bootloader [systemd-boot]
bootctl install
echo -e "title   Arch Linux\nlinux   /vmlinuz-linux\ninitrd  /intel-ucode.img\ninitrd  /initramfs-linux.img\noptions rw root=$root" > /boot/loader/entries/arch.conf
echo -e "timeout 5\nconsole-mode max" > /boot/loader/loader.conf

# - autologin tty1 & sudoers & make me :3
mkdir /etc/systemd/system/getty@tty1.service.d
echo -e "[Service]\nExecStart=\nExecStart=-/usr/bin/agetty --noissue --autologin wael --noclear %I 38400 linux" > /etc/systemd/system/getty@tty1.service.d/override.conf
sed -i '82s/. //' /etc/sudoers
useradd -m -G wheel -s /bin/zsh wael
passwd && passwd wael
