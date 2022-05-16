#!/usr/bin/env -S bash -xe
source vars.conf

export REPO=https://mirrors.dotsrc.org/voidlinux/current
export ARCH=x86_64
XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R $REPO \
  base-minimal linux-mainline{,-headers} kbd \
  btrfs-progs dosfstools gummiboot pciutils usbutils iproute2 \
  socklog-void xtools git ncurses libgcc file man man{,-pages} \
  dumb_runtime_dir dhcpcd opendoas zsh acpid

## neccessary mounting for literally anything
for mount in sys dev proc; do
  mount --rbind /$mount /mnt/$mount && mount --make-rslave /mnt/$mount
done

## genfstab
chmod +x genfstab && cp -v genfstab /mnt/usr/bin/ && ./genfstab -U /mnt >> /mnt/etc/fstab

## create user & {root,user} password, autologin, doas conf
useradd -R /mnt -mG audio,video,input,kvm,socklog -s /bin/zsh wael
echo "$USERSTRAP:$USERPASSWD" | chpasswd -R /mnt -c SHA512
echo "root:$ROOTPASSWD" | chpasswd -R /mnt -c SHA512
sed -i "/GETTY_ARGS=/s/\"$/ --autologin $USERSTRAP&/" /mnt/etc/sv/agetty-tty1/conf
cat > /mnt/etc/doas.conf << EODOASCONF
permit wael
permit persist wael
permit nopass wael cmd xbps-install
EODOASCONF

# glibc locale, hostname, dmesg_restrict, nameserver, gummiboot {install,flags}, dumb_runtime_dir, dracut conf, xbps, services
sed -i '/^#en_US.UTF-8/s/.//' /mnt/etc/default/libc-locales
echo "$HOSTNAMESTRAP" > /mnt/etc/hostname
mkdir -pv /mnt/etc/sysctl.d && echo "kernel.dmesg_restrict=0" > /mnt/etc/sysctl.d/99-dmesg-user.conf
echo "nameserver 192.168.1.1" > /mnt/etc/resolv.conf
chroot /mnt gummiboot install
echo "rw loglevel=4 mitigations=off" > /mnt/boot/loader/void-options.conf
echo "session   optional   pam_dumb_runtime_dir.so" >> /mnt/etc/pam.d/system-login
printf "%s\n" {hostonly{,_cmdline},use_fstab,nofscks,show_modules}=yes > /mnt/etc/dracut.conf.d/options.conf
echo 'compress="cat"' >> /mnt/etc/dracut.conf.d/options.conf
echo 'omit_drivers+=" iTCO_wdt "' > /mnt/etc/dracut.conf.d/modules.conf
mkdir -p /mnt/etc/xbps.d
printf "%s\n" ignorepkg=linux{,-headers,-firmware-{amd,broadcom}} > /mnt/etc/xbps.d/99-ignore.conf
xbps-remove -y -r /mnt linux{,-headers,-firmware-{amd,broadcom}}
xbps-install -Sy -r /mnt -R $REPO void-repo-{multilib{,-nonfree},nonfree}
cp /mnt/usr/share/xbps.d/*-repository-*.conf /mnt/etc/xbps.d/
sed -i "s|https://alpha.de.repo.voidlinux.org/current|$REPO|g" /mnt/etc/xbps.d/*-repository-*.conf

for sv in acpid dhcpcd socklog-unix nanoklogd; do
  chroot /mnt ln -sfv /etc/sv/$sv /etc/runit/runsvdir/default
done

cat > /mnt/etc/rc.conf << EORCCONF
# /etc/rc.conf - system configuration for void
HOSTNAME="$HOSTNAMESTRAP"
# RTC, UTC, localtime.
HARDWARECLOCK="UTC"
TIMEZONE="Asia/Riyadh"
KEYMAP="us"
#FONT="ter-v12n"
#TTYS=
# hybrid, legacy, unified.
CGROUP_MODE=hybrid
EORCCONF

# check packages just for safety
xbps-pkgdb -r /mnt 
