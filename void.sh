#!/bin/bash
# https://gist.github.com/tobi-wan-kenobi/bff3af81eac27e210e1dc88ba660596e
# https://gist.github.com/gbrlsnchs/9c9dc55cd0beb26e141ee3ea59f26e21
BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
REPO="https://alpha.de.repo.voidlinux.org/current"
ARCH=x86_64
HOSTNAME=br
ROOT="/dev/sda2"
ESP="/dev/sda1"

mkfs.vfat -nGRUB -F32 $ESP
mkfs.btrfs -L void -f $ROOT
mount -o $BTRFS_OPTS $ROOT /mnt
mkdir /mnt/efi
mount -o rw,noatime $ESP /mnt/efi

XBPS_ARCH=$ARCH xbps-install -Sy -r /mnt -R $REPO base-system base-devel btrfs-progs grub-x86_64-efi elogind
for dir in dev proc sys run; do mount --rbind /$dir /mnt/$dir; mount --make-rslave /mnt/$dir; done
cp /etc/resolv.conf /mnt/etc/

chroot /mnt xbps-install -Syu void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
chroot /mnt xbps-install -Sy intel-ucode nvidia zsh zsh-syntax-highlighting 

echo $HOSTNAME > /mnt/etc/hostname
cat <<EOF > /mnt/etc/rc.conf
HOSTNAME="$HOSTNAME"
HARDWARECLOCK="UTC"
TIMEZONE="Asia/Riyadh"
KEYMAP="us"
EOF

echo LANG=en_US.UTF-8 > /mnt/etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/default/libc-locales
sed -i "/GETTY_ARGS=/s/\"$/ --autologin wael&/" /mnt/etc/sv/agetty-tty1/conf
chroot /mnt useradd -m -G wheel,input,video,kvm,storage -s /bin/zsh wael
chroot /mnt passwd wael

ROOT_UUID=$(blkid -s UUID -o value $ROOT)
ESP_UUID=$(blkid -s UUID -o value $ESP)
cat <<EOF > /mnt/etc/fstab
UUID=$ROOT_UUID /       btrfs $BTRFS_OPTS 0 1
UUID=$ESP_UUID /efi   vfat  defaults,noatime 0 2
tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0
EOF

chroot /mnt grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id="Void Linux"
chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
chroot /mnt ln -s /etc/sv/dbus /etc/runit/runsvdir/default/
chroot /mnt ln -s /etc/sv/dhcpcd /etc/runit/runsvdir/default/
chroot /mnt ln -s /etc/sv/elogind /etc/runit/runsvdir/default/
chroot /mnt passwd
chroot /mnt xbps-reconfigure -fa
umount -R /mnt
