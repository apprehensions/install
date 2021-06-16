#!/bin/bash
# https://github.com/Bugswriter/arch-linux-magic/blob/master/arch_install.sh
name=br
echo "root: "
read root
echo "esp: "
read esp

mkfs.btrfs -f $root
mount $root /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount -R /mnt
mount -o compress=zstd,subvol=/@ $root /mnt
mkdir /mnt/home
mount -o compress=zstd,subvol=/@home $root /mnt
mkdir /mnt/boot
mount $esp /mnt/boot

pacstrap /mnt linux linux-firmware linux-headers base base-devel intel-ucode btrfs-progs nvidia 
genfstab -U /mnt >> /mnt/etc/fstab
cp -v -r root/etc /mnt
cp -v -r root/boot /mnt
echo $name > /mnt/etc/hostname
echo "127.0.0.1 localhost" > /mnt/etc/hosts
echo "::1       localhost" >> /mnt/etc/hosts
echo "127.0.1.1 $name.localdomain $name" >> /mnt/etc/hosts
echo "wael ALL=(ALL) ALL" > /mnt/etc/sudoers.d/wael
echo "LANG=en_us.UTF-8" > /mnt/etc/locale.conf
echo "en_us.UTF-8 UTF-8" > /mnt/etc/locale.gen
echo "options rw root=$root rootflags=subvol=@" >> /mnt/boot/loader/entries/arch.conf
sed '1,/^#part2$/d' pc.sh > /mnt/pc-p2.sh
chmod +x /mnt/arch_install2.sh
arch-chroot /mnt ./arch_install2.sh
exit 

#part2
bootctl install
timedatectl set-ntp true
timedatectl set-timezone Asia/Riyadh
useradd -m -s /bin/zsh wael
locale-gen
pacman -S git wget pipewire pipewire-alsa pipewire-pulse xorg xorg-xinit xclip zsh ttf-hanazono ttf-jetbrains-mono
git clone https://aur.archlinux.org/paru.git /usr/src/paru
systemctl enable systemd-networkd
systemctl enable reflector.timer
systemctl enable fstrim.timer  
systemctl enable sshd
passwd wael && passwd

