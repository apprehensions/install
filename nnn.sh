#!/bin/bash
echo "note that i mention the root,esp,swap im asking you for the drive codes, aka '/dev/sda1,sda2,sda3' etc. \n"
echo "root: "
read rootpart
echo "esp: "
read esppart
echo "swap: "
read swappart
echo "your name: "
read name
echo "machine name: "
read hostname

mkfs.btrfs -f $root
mount $root /mnt
mkfs.vfat $esp
mkdir -p /mnt/boot/efi
mkswap $swappart
swapon $swappart
mount $esp /mnt/boot/efi
pacstrap /mnt linux linux-firmware linux-headers base base-devel intel-ucode btrfs-progs xf86-video-intel mesa zsh grub efibootmgr 
genfstab -U /mnt >> /mnt/etc/fstab
echo $hostname > /mnt/etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $name.localdomain $name" >> /etc/hosts
echo "$name ALL=(ALL) ALL" > /etc/sudoers.d/wael
echo "LANG=en_us.UTF-8" > /etc/locale.conf
echo "en_us.UTF-8 UTF-8" > /etc/locale.gen
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf
arch-chroot /mnt pacman -S networkmanager mtools dosfstools xdg-user-dirs xdg-utils bluez bluez-utils pulseaudio pulseaudio-alsa acpi acpid
arch-chroot /mnt timedatectl set-ntp true
arch-chroot /mnt timedatectl set-timezone America/Indiana/Indianapolis
arch-chroot /mnt systemctl enable bluetooth
arch-chroot /mnt systemctl enable acpid
arch-chroot /mnt useradd -m -s /bin/zsh $name
arch-chroot /mnt locale-gen
echo "password for you: "
arch-chroot /mnt passwd $name
echo "password for root: "
arch-chroot /mnt passwd
