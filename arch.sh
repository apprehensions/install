#!/bin/bash
export BTRFS_OPTS="rw,noatime,ssd,compress=zstd,space_cache"
export ROOT="/dev/sda2"
export ESP="/dev/sda1"

# - make root
mkfs.btrfs -L root -f $ROOT
mount -o $BTRFS_OPTS $ROOT /mnt

# - make esp 
mkfs.vfat -nBOOP -F32 $ESP
echo -e "t\n1\n1\nw" | fdisk /dev/sda
mkdir -pv /mnt/boot	
mount -o rw,noatime $ESP /mnt/boot

reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
sed -ibak -e '37s/.//' -e '37s/5/24/' /etc/pacman.conf
pacstrap /mnt linux linux-firmware linux-headers base base-devel btrfs-progs
mv /etc/pacman.confbak /etc/pacman.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/
genfstab -U /mnt >> /mnt/etc/fstab

sed '1,/^# - post$/d' $0 > /mnt/post-install.sh
chmod a+x /mnt/post-install.sh
arch-chroot /mnt ./post-install.sh
umount -R /mnt
exit

# - ===========================================================
# - post

# - locale
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

# - host
echo $HOSTNAME > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts 
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

# - time
ln -sf /usr/share/zoneinfo/Asia/Riyadh /etc/localtime
hwclock --systohc

# - pacman
sed -i '33s/.//' /etc/pacman.conf # color
sed -i -e '37s/.//' -e '37s/5/12/' /etc/pacman.conf # parallel downloads
sed -i '93,94s/.//' /etc/pacman.conf # enable multilib
pacman --noconfirm -Sy zsh terminus-font reflector iwd \
											 nvidia-dkms nvidia-utils nvidia-settings \
											 lib32-nvidia-utils
# - modules
echo "blacklist i2c_nvidia_gpu" > /etc/modprobe.d/blacklist.conf 
echo "blacklist iTCO_wdt" >> /etc/modprobe.d/blacklist.conf 
echo "options nvidia-drm modeset=1" >> /etc/modprobe.d/nvidia-drm.conf 
sed -i '7s/()/(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
mkinitcpio -P

# systemd-networkd
cat <<EOF > /etc/systemd/network/lan.network
[Match]
Name=eno2

[Network]
DHCP=yes
EOF 

# iwd 
mkdir -pv /mnt/etc/iwd
cat <<EOF > /mnt/etc/iwd/main.conf
[General]
UseDefaultInterface=true
EOF

# services
systemctl enable systemd-networkd
systemctl enable iwd

# user
sed -i '82s/. //' /etc/sudoers
useradd -mG wheel,audio,video,kvm,storage -s /bin/zsh wael
passwd && passwd wael 

mkdir /etc/systemd/system/getty@tty1.service.d
cat <<EOF > /etc/systemd/system/getty@tty1.service.d/override.conf 
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --noissue --autologin wael --noclear %I \$TERM"
EOF

rm /post-install.sh
echo "your install is done now go outside"
