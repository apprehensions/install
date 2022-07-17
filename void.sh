#!/usr/bin/env -S bash -xe
. source.conf

export REPO=https://mirror.fit.cvut.cz/voidlinux
XBPS_ARCH=x86_64 xbps-install -S -r /mnt -R $REPO/current ${PKGS}

mount -t efivarfs efivarfs /sys/firmware/efi/efivars
for mount in sys dev proc; do mount --rbind /$mount /mnt/$mount; done

useradd -R /mnt -mG audio,video,input,kvm,socklog,plugdev,adbusers,bluetooth wael
echo "wael:meow" | chpasswd -R /mnt -c SHA512
echo "root:meow" | chpasswd -R /mnt -c SHA512
sed -i "/GETTY_ARGS=/s/\"$/ --autologin wael&/" /mnt/etc/sv/agetty-tty1/conf
sed -i '/^.*pam_dumb_runtime.*/s/.//' /mnt/etc/pam.d/system-login
echo ephemera >/mnt/etc/hostname
chroot /mnt ln -sf /usr/share/zoneinfo/Asia/Riyadh /etc/localtime
sed -i '/^#en_US.UTF-8/s/.//' /mnt/etc/default/libc-locales
mkdir -pv /mnt/etc/sysctl.d
echo "kernel.dmesg_restrict=0" > /mnt/etc/sysctl.d/99-dmesg-user.conf

cat <<EOFSTAB > /mnt/etc/fstab
LABEL=${ROOTLABEL} / btrfs ${BTRFSOPTS} 0 0
LABEL=${ESPLABEL} /boot vfat defaults 0 2
EOFSTAB
cat <<EODOASCONF > /mnt/etc/doas.conf
permit persist wael
permit nopass wael cmd xbps-install
EODOASCONF
cat <<EOMODPROBENVIDIACONF > /mnt/etc/modprobe.d/nvidia.conf
blacklist nouveau
options nvidia-drm modeset=1
options nvidia NVreg_UsePageAttributeTable=1
EOMODPROBENVIDIACONF
cat <<EODRACUTCONF > /mnt/etc/dracut.conf.d/options.conf
hostonly=yes
hostonly_cmdline=yes
show_modules=yes
compress="cat"
EODRACUTCONF
cat <<EOEFISTUB > /mnt/etc/default/efibootmgr-kernel-hook
MODIFY_EFI_ENTRIES=1
OPTIONS="rw mitigations=off loglevel=6 nowatchdog"
DISK=$DISK
PART=1
EOEFISTUB

mkdir -p /mnt/etc/xbps.d
xbps-install -Sy -r /mnt -R $REPO/current \
	void-repo-multilib void-repo-multilib-nonfree void-repo-nonfree
cp /mnt/usr/share/xbps.d/*-repository-*.conf /mnt/etc/xbps.d/
sed -i "s|https://repo-default.voidlinux.org|$REPO|g" /mnt/etc/xbps.d/*-repository-*.conf
for service in acpid dhcpcd socklog-unix nanoklogd dbus bluetoothd; do
  chroot /mnt ln -sfv /etc/sv/$service /etc/runit/runsvdir/default
done
xbps-install -r /mnt -Syuv intel-ucode nvidia
xbps-reconfigure -r /mnt -fa
