#!/usr/bin/env bash
source vars.conf
set -xe

export REPO=https://mirrors.dotsrc.org/voidlinux/current
export ARCH=x86_64
XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R $REPO \
  "base-minimal" "linux-mainline" "linux-mainline-headers" \
  "btrfs-progs" "dosfstools" "gummiboot" "socklog-unix" \
  "pciutils" "usbutils" "xtools" "git" "iproute2" "iputils" \
  "ncurses" "libgcc" "file" "man" "man-pages" "kbd" "dumb_runtime_dir" \
  "rtkit" "dbus" "seatd" "dhcpcd" "bluez" "acpid" "zsh" "opendoas"

# disk
for mount in sys dev proc; do
  mount --rbind /$mount /mnt/$mount && mount --make-rslave /mnt/$mount
done

chmod +x genfstab
cp -v genfstab /mnt/usr/bin/
./genfstab -U /mnt >> /mnt/etc/fstab

# services
for sv in dbus rtkit seatd acpid dhcpcd bluetoothd socklog-unix nanoklogd; do
  chroot /mnt ln -sfv /etc/sv/$sv /etc/runit/runsvdir/default
done

# user & {root,user} password
useradd -R /mnt -mG audio,video,input,kvm,bluetooth,socklog,_seatd,rtkit -s /bin/zsh wael
echo "wael:$USERPASSWD" | chpasswd -R /mnt -c SHA512
echo "root:$ROOTPASSWD" | chpasswd -R /mnt -c SHA512
# autologin
sed -i "/GETTY_ARGS=/s/\"$/ --autologin wael&/" /mnt/etc/sv/agetty-tty1/conf

# doas
cat > /mnt/etc/doas.conf << EOCONF
permit wael
permit persist wael
permit nopass wael cmd xbps-install
EOCONF

# other: glibc locales, hostname, user dmesg read, install bootloader, {dracut,rc} conf
sed -i '/^#en_US.UTF-8/s/.//' /mnt/etc/default/libc-locales
echo "$HOSTNAMESTRAP" > /mnt/etc/hostname
mkdir -pv /mnt/etc/sysctl.d
echo "kernel.dmesg_restrict=0" > /mnt/etc/sysctl.d/10-dmesg-user.conf
echo "nameserver 192.168.1.1" > /mnt/etc/resolv.conf
chroot /mnt gummiboot install
echo "rw loglevel=4 mitigations=off" > /mnt/boot/loader/void-options.conf
echo "session   optional   pam_dumb_runtime_dir.so" >> /mnt/etc/pam.d/system-login

cat > /mnt/etc/dracut.conf.d/options.conf << EODRACUTCONF
hostonly=yes
hostonly_cmdline=yes

use_fstab=yes
nofscks=yes

show_modules="yes"

compress="cat"
EODRACUTCONF

cat > /mnt/etc/dracut.conf.d/modules.conf << EODRACUTCONF
omit_drivers+=" iTCO_wdt "
omit_drivers+=" nouveau "
omit_dracutmodules+=" bash terminfo "
EODRACUTCONF

cat > /mnt/etc/rc.conf << EORCCONF
# /etc/rc.conf - system configuration for void

HOSTNAME="$HOSTNAMESTRAP"

# RTC, UTC, localtime.
HARDWARECLOCK="UTC"
TIMEZONE="Asia/Riyadh"

KEYMAP="us"
FONT="ter-v12n"
#TTYS=

# hybrid, legacy, unified.
CGROUP_MODE=hybrid
EORCCONF

## xbps
mkdir -p /mnt/etc/xbps.d

# ignore
cat > /mnt/etc/xbps.d/99-ignore.conf << EOIGNORE
ignorepkg=linux-headers
ignorepkg=linux
ignorepkg=linux-firmware-amd
ignorepkg=linux-firmware-broadcom
EOIGNORE
xbps-remove -y -r /mnt linux-firmware-{amd,broadcom} linux linux-headers

# repos
xbps-install -Sy -r /mnt -R $REPO void-repo-{multilib{,-nonfree},nonfree}
cp /mnt/usr/share/xbps.d/*-repository-*.conf /mnt/etc/xbps.d/
sed -i "s|https://alpha.de.repo.voidlinux.org/current|$REPO|g" /mnt/etc/xbps.d/*-repository-*.conf

# post
xbps-reconfigure -r /mnt -fa
xbps-install -Syuv -r /mnt
