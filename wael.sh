#!/bin/bash
echo "$(tput bold)root partition: $(tput sgr0)" 
read root
echo "$(tput bold)efi partition: $(tput sgr0)"
read esp
mkfs.btrfs -L arch -f $root
mkfs.vfat -n EFI -F 32 $esp
mount $root -o compress=zstd /mnt
mkdir /mnt/boot
mount $esp /mnt/boot

sed -ibak -e '37s/.//' -e '37s/5/10/' /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
pacstrap /mnt linux linux-firmware linux-headers base base-devel btrfs-progs
cp /etc/pacman.confbak /etc/pacman.conf
genfstab -U /mnt >> /mnt/etc/fstab

name=br
echo $name > /mnt/etc/hostname
echo -e "127.0.0.1 localhost\n::1       localhost \n127.0.1.1 $hostname.localdomain $hostname" > /mnt/etc/hosts
mkdir /mnt/etc/systemd/system/getty@tty1.service.d
echo -e "[Service]\nExecStart=\nExecstart=-/usr/bin/agetty --noissue\nTTYVTDisallocate=no" > /mnt/etc/systemd/system/getty@tty1.service.d/override.conf
echo -e "[Match]\nName=eno1\n\n[Network]\nDHCP=yes" > /mnt/etc/systemd/network/lan.network
cp -r /etc/resolv.conf /mnt/etc/resolv.conf
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
echo "KEYMAP=us" > /mnt/etc/vconsole.conf
sed -i '177s/.//' /mnt/etc/locale.gen
sed -i '82s/. //' /mnt/etc/sudoers
sed -i -e '33s/.//' -e '37s/.//' -e '93,94s/.//' /mnt/etc/pacman.conf
sed '1,/^#part2$/d' wael.sh > /mnt/part2.sh
chmod +x /mnt/part2.sh
arch-chroot /mnt ./part2.sh
exit 

#part2
locale-gen
reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
timedatectl set-ntp true
ln -sf /usr/share/zoneinfo/Asia/Riyadh /etc/localtime
hwclock --systohc
pacman --noconfirm -Syu git wget neofetch openssh 
bootctl install
echo -e "title   Arch Linux\nlinux   /vmlinuz-linux\ninitrd  /initramfs-linux.img\noptions rw root=$root" > /boot/loader/entries/arch.conf
echo -e "timeout 5\nconsole-mode max" > /boot/loader/loader.conf
git clone https://aur.archlinux.org/paru.git /usr/src/paru && chmod 777 /usr/src/paru
systemctl enable systemd-networkd
systemctl enable fstrim.timer
systemctl enable sshd
useradd -m -G wheel -s /bin/zsh wael
passwd && passwd wael
