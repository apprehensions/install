#!/usr/bin/env -S bash -xe
export REPO=https://mirror.fit.cvut.cz/voidlinux/current
export ARCH=x86_64
XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R $REPO \
  base-minimal base-devel linux-mainline{,-headers} kbd \
  btrfs-progs dosfstools gummiboot pciutils usbutils iproute2 iputils \
  socklog-void xtools git ncurses libgcc file man{,-pages} \
  dumb_runtime_dir dhcpcd opendoas zsh acpid

## neccessary mounting for literally anything
mount -t efivarfs efivarfs /sys/firmware/efi/efivars
for mount in sys dev proc; do
  mount --rbind /$mount /mnt/$mount && mount --make-rslave /mnt/$mount
done

# good luck trying to understand this
chmod +x genfstab
cp -v genfstab /mnt/usr/bin/
./genfstab -L /mnt >> /mnt/etc/fstab
useradd -R /mnt -mG audio,video,input,kvm,socklog,plugdev -s /bin/zsh wael
echo "wael:meow" | chpasswd -R /mnt -c SHA512
echo "root:meow" | chpasswd -R /mnt -c SHA512
echo ephemera > /mnt/etc/hostname
chroot /mnt ln -sf /usr/share/zoneinfo/Asia/Riyadh /etc/localtime
sed -i "/GETTY_ARGS=/s/\"$/ --autologin wael&/" /mnt/etc/sv/agetty-tty1/conf
printf '%s\n%s\n' 'permit persist wael' 'permit nopass wael cmd xbps-install' > /mnt/etc/doas.conf
sed -i '/^.*pam_dumb_runtime.*/s/.//' /mnt/etc/pam.d/system-login
sed -i '/^#en_US.UTF-8/s/.//' /mnt/etc/default/libc-locales
echo "nameserver 192.168.1.1" > /mnt/etc/resolv.conf
printf "%s\n" {hostonly{,_cmdline},use_fstab,nofscks,show_modules}=yes > /mnt/etc/dracut.conf.d/options.conf
printf '%s\n%s\n' 'blacklist nouveau' options\ nvidia{-drm\ modeset,\ NVreg_UsePageAttributeTable}=1 > /mnt/etc/modprobe.d/nvidia.conf
echo 'compress="cat"' >> /mnt/etc/dracut.conf.d/options.conf
mkdir -pv /mnt/etc/sysctl.d
echo "kernel.dmesg_restrict=0" > /mnt/etc/sysctl.d/99-dmesg-user.conf
chroot /mnt gummiboot install
echo "rw loglevel=3 splash quiet mitigations=off" > /mnt/boot/loader/void-options.conf
mkdir -p /mnt/etc/xbps.d
xbps-install -Sy -r /mnt -R $REPO void-repo-{multilib{,-nonfree},nonfree}
cp /mnt/usr/share/xbps.d/*-repository-*.conf /mnt/etc/xbps.d/
sed -i "s|https://repo-default.voidlinux.org|$REPO|g" /mnt/etc/xbps.d/*-repository-*.conf
printf "%s\n" ignorepkg=linux{,-headers,-firmware-{amd,broadcom}} > /mnt/etc/xbps.d/99-ignore.conf
xbps-remove -y -r /mnt linux{,-headers,-firmware-{amd,broadcom}}
for sv in acpid dhcpcd socklog-unix nanoklogd; do
  chroot /mnt ln -sfv /etc/sv/$sv /etc/runit/runsvdir/default
done
xbps-reconfigure -fa
