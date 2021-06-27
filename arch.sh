#!/bin/bash
# https://github.com/Bugswriter/arch-linux-magic/blob/master/arch_install.sh
# https://gitlab.com/eflinux/arch-basic/-/blob/master/install-uefi.sh
# I DONT KNOW HOW TO SCTI PT -LKE S HEL PEM M
name=br
echo "root: "
read root
echo "esp: "
read esp

mkfs.btrfs -L arch -f $root
mkfs.vfat -n GUMMI -F 32 $esp
mount $root /mnt
btrfs subvolume create /mnt/@
btrfs subvolume set-default /mnt/@
umount -R /mnt
mount -o compress=zstd,subvol=@ $root /mnt
mkdir /mnt/boot
mount $esp /mnt/boot

pacstrap /mnt linux linux-firmware linux-headers base base-devel intel-ucode btrfs-progs nvidia 
genfstab -U /mnt >> /mnt/etc/fstab
# i am a very lazy person so, imm just moving instead of echoing (please don't do this at home)
cp -v -r root/etc /mnt
cp -v -r root/boot /mnt
# neither do i know how to use sed
sed -i '177s/.//' /mnt/etc/locale.gen
sed -i '33s/.//' /mnt/etc/pacman.conf
sed -i '36s/.//' /mnt/etc/pacman.conf
sed -i '37s/.//' /mnt/etc/pacman.conf
sed -i '37s/5/6/' /etc/pacman.conf
sed '1,/^#part2$/d' arch.sh > /mnt/part2.sh
chmod +x /mnt/part2.sh
arch-chroot /mnt ./part2.sh
exit 

#part2
bootctl install
timedatectl set-ntp true
timedatectl set-timezone Asia/Riyadh
pacman -S git wget zsh nvidia-settings neofetch
useradd -m -s /bin/zsh wael
locale-gen
git clone https://aur.archlinux.org/paru.git /usr/src/paru && chmod 777 /usr/src/paru
systemctl enable systemd-networkd
systemctl enable fstrim.timer  
systemctl enable sshd
passwd wael && passwd

