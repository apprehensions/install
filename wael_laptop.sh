#!/bin/bash
# https://gist.github.com/tobi-wan-kenobi/bff3af81eac27e210e1dc88ba660596e
# https://gist.github.com/gbrlsnchs/9c9dc55cd0beb26e141ee3ea59f26e21
# variables
BTRFS_OPTS="rw,relatime,ssd,compress=zstd,space_cache,commit=120"
REPO=https://alpha.de.repo.voidlinux.org/current
XBPS_ARCH=x86_64
HOSTNAME=yoga
ROOT="/dev/nvme0n1p2"
BOOT="/dev/nvme0n1p1"

mkfs.vfat -nGRUB -F32 $ESP
cryptsetup -y -v luksFormat -s=512 $ROOT
cryptsetup open $ROOT kroot
mkfs.btrfs -L void -f /dev/mapper/kroot
mount -o $BTRFS_OPTS /dev/mapper/kroot /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snaps
btrfs subvolume set-default @
umount -R /mnt

mount -o $BTRFS_OPTS,subvol=@ /dev/mapper/kroot /mnt
mkdir -p /mnt/home
mount -o $BTRFS_OPTS,subvol=@home /dev/mapper/kroot /mnt/home
mkdir -p /mnt/.snaps
mount -o $BTRFS_OPTS,subvol=@snaps /dev/mapper/kroot /mnt/.snaps
mkdir -p /mnt/boot
mount -o rw,noatime $BOOT /mnt/boot

mkdir -p /mnt/var/cache
btrfs subvolume create /mnt/var/cache/xbps
btrfs subvolume create /mnt/var/tmp
btrfs subvolume create /mnt/srv

xbps-install -Sy -R $REPO -r /mnt base-system base-devel btrfs-progs cryptsetup grub-x86_64-efi iwd
for dir in dev proc sys run; do mount --rbind /$dir /mnt/$dir; mount --make-rslave /mnt/$dir; done

echo LANG=en_US.UTF-8 > /mnt/etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/default/libc-locales
echo 'add_dracutmodules+="crypt btrfs"' >> /mnt/etc/dracut.conf
echo hostonly=yes >> /mnt/etc/dracut.conf
echo 'tmpdir=/tmp' >> /mnt/etc/dracut.conf
echo -e "127.0.0.1 localhost\n::1       localhost \n127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" > /mnt/etc/hosts
cp -P /etc/resolv.conf /mnt/etc/

ROOT_UUID=$(blkid -s UUID -o value $ROOT)
BOOT_UUID=$(blkid -s UUID -o value $BOOT)
cat <<EOF > /mnt/etc/fstab
UUID=$ROOT_UUID /       btrfs $BTRFS_OPTS,subvol=@ 0 1
UUID=$BOOT_UUID /boot   vfat  defaults,noatime 0 2
UUID=$ROOT_UUID /home   btrfs $BTRFS_OPTS,subvol=@home 0 2
UUID=$ROOT_UUID /.snaps btrfs $BTRFS_OPTS,subvol=@snaps 0 2
tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0
EOF

cat <<EOF > /mnt/etc/rc.rc.conf
HOSTNAME="$HOSTNAME"
HARDWARECLOCK="UTC"
TIMEZONE="Asia/Riyadh"
KEYMAP="us"
EOF

chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id="Void Linux"
cat <<EOF > /mnt/etc/default/grub
# /etc/default/grub - grub configuration
GRUB_DEFAULT=0
GRUB_TIMEOUT=2
GRUB_DISTRIBUTOR="Void"
GRUB_ENABLE_CRYPTODISK=y
GRUB_CMDLINE_LINUX="cryptdevice=UUID=$ROOT_UUID:kroot:allow-discards"
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=4 rd.auto=1"
EOF
chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
ln -s /mnt/etc/sv/acpid /mnt/var/service/
ln -s /mnt/etc/sv/iwd /mnt/var/service/
ln -s /mnt/etc/sv/dbus /mnt/var/service
chroot /mnt xbps-reconfigure -f glibc-locales
chroot /mnt xbps-install -Su void-repo-nonfree void-repo-multilib
chroot /mnt xbps-install -Sy intel-ucode
chroot /mnt useradd -m -G wheel,input,video -s /bin/zsh wael
chroot /mnt passwd && passwd wael
