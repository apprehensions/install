#!/usr/bin/env -S bash -xe
export REPO=https://mirror.fit.cvut.cz/voidlinux
export ARCH=x86_64
XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R $REPO/current \
  base-minimal base-devel linux-mainline{,-headers} kbd intel-ucode \
  btrfs-progs dosfstools gummiboot pciutils usbutils iproute2 \
  socklog-void xtools git ncurses file man{,-pages} \
  dumb_runtime_dir dhcpcd opendoas acpid nvidia dbus \
  exa grc android-udev-rules android-tools bluez

## neccessary mounting for literally anything
mount -t efivarfs efivarfs /sys/firmware/efi/efivars
for mount in sys dev proc; do
  mount --rbind /$mount /mnt/$mount
done

# good luck trying to understand this
chmod +x genfstab
cp -v genfstab /mnt/usr/bin/
./genfstab -U /mnt > /mnt/etc/fstab
useradd -R /mnt -mG audio,video,input,kvm,socklog,plugdev,adbusers,bluetooth -s /bin/zsh wael
echo "wael:meow" | chpasswd -R /mnt -c SHA512
echo "root:meow" | chpasswd -R /mnt -c SHA512
echo ephemera > /mnt/etc/hostname
chroot /mnt ln -sf /usr/share/zoneinfo/Asia/Riyadh /etc/localtime
sed -i "/GETTY_ARGS=/s/\"$/ --autologin wael&/" /mnt/etc/sv/agetty-tty1/conf
printf '%s\n%s\n' 'permit persist wael' 'permit nopass wael cmd xbps-install' > /mnt/etc/doas.conf
sed -i '/^.*pam_dumb_runtime.*/s/.//' /mnt/etc/pam.d/system-login
sed -i '/^#en_US.UTF-8/s/.//' /mnt/etc/default/libc-locales
printf '%s\n' nameserver\ {9.9.9.9,149.112.112.112} > /mnt/etc/resolv.conf
printf "%s\n" {hostonly{,_cmdline},show_modules}=yes > /mnt/etc/dracut.conf.d/options.conf
echo 'compress="cat"' >> /mnt/etc/dracut.conf.d/options.conf
printf '%s\n%s\n' 'blacklist nouveau' options\ nvidia{-drm\ modeset,\ NVreg_UsePageAttributeTable}=1 > /mnt/etc/modprobe.d/nvidia.conf
mkdir -pv /mnt/etc/sysctl.d
echo "kernel.dmesg_restrict=0" > /mnt/etc/sysctl.d/99-dmesg-user.conf
chroot /mnt gummiboot install
echo "rw mitigations=off nowatchdog" > /mnt/boot/loader/void-options.conf
mkdir -p /mnt/etc/xbps.d
xbps-install -Sy -r /mnt -R $REPO/current void-repo-{multilib{,-nonfree},nonfree}
cp /mnt/usr/share/xbps.d/*-repository-*.conf /mnt/etc/xbps.d/
sed -i "s|https://repo-default.voidlinux.org|$REPO|g" /mnt/etc/xbps.d/*-repository-*.conf
printf "%s\n" ignorepkg=linux{,-headers,-firmware-{amd,broadcom}} > /mnt/etc/xbps.d/99-ignore.conf
xbps-remove -y -r /mnt linux{,-headers,-firmware-{amd,broadcom}}
for sv in acpid dhcpcd socklog-unix nanoklogd dbus bluetoothd; do
  chroot /mnt ln -sfv /etc/sv/$sv /etc/runit/runsvdir/default
done
xbps-reconfigure -r /mnt -fa
