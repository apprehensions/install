#!/usr/bin/env -S bash -xe
source vars.conf

export REPO=https://void.cijber.net/current
export ARCH=x86_64
XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R $REPO \
  base-minimal base-devel linux-mainline{,-headers} kbd \
  btrfs-progs dosfstools gummiboot pciutils usbutils iproute2 \
  socklog-void xtools git ncurses libgcc file man{,-pages} \
  dumb_runtime_dir dhcpcd opendoas zsh acpid

## neccessary mounting for literally anything
mount -t efivarfs efivarfs /sys/firmware/efi/efivars
for mount in sys dev proc; do
  mount --rbind /$mount /mnt/$mount && mount --make-rslave /mnt/$mount
done

## genfstab
chmod +x genfstab
cp -v genfstab /mnt/usr/bin/
./genfstab -L /mnt >> /mnt/etc/fstab

## user related
useradd -R /mnt -mG audio,video,input,kvm,socklog -s /bin/zsh wael
echo "wael:$UPSWD" | chpasswd -R /mnt -c SHA512
echo "root:$RPSWD" | chpasswd -R /mnt -c SHA512
sed -i "/GETTY_ARGS=/s/\"$/ --autologin wael&/" /mnt/etc/sv/agetty-tty1/conf
echo 'permit persist wael\npermit nopass wael cmd xbps-install' > /mnt/etc/doas.conf
echo "session   optional   pam_dumb_runtime_dir.so" >> /mnt/etc/pam.d/system-login

# something something related
sed -i '/^#en_US.UTF-8/s/.//' /mnt/etc/default/libc-locales
echo "nameserver 192.168.1.1" > /mnt/etc/resolv.conf

# kernel(?) related
printf "%s\n" {hostonly{,_cmdline},use_fstab,nofscks,show_modules}=yes > /mnt/etc/dracut.conf.d/options.conf
echo 'compress="cat"' >> /mnt/etc/dracut.conf.d/options.conf
echo 'omit_drivers+=" iTCO_wdt "' > /mnt/etc/dracut.conf.d/modules.conf
mkdir -pv /mnt/etc/sysctl.d
echo "kernel.dmesg_restrict=0" > /mnt/etc/sysctl.d/99-dmesg-user.conf
chroot /mnt gummiboot install
echo "rw loglevel=4 mitigations=off" > /mnt/boot/loader/void-options.conf

# xbps related
mkdir -p /mnt/etc/xbps.d
cp /mnt/usr/share/xbps.d/*-repository-*.conf /mnt/etc/xbps.d/
sed -i "s|https://alpha.de.repo.voidlinux.org/current|$REPO|g" /mnt/etc/xbps.d/*-repository-*.conf
printf "%s\n" ignorepkg=linux{,-headers,-firmware-{amd,broadcom}} > /mnt/etc/xbps.d/99-ignore.conf
xbps-remove -y -r /mnt linux{,-headers,-firmware-{amd,broadcom}}
xbps-install -Sy -r /mnt -R $REPO void-repo-{multilib{,-nonfree},nonfree}

# services
for sv in acpid dhcpcd socklog-unix nanoklogd; do
  chroot /mnt ln -sfv /etc/sv/$sv /etc/runit/runsvdir/default
done

# i know i will get killed for this, BUT 
# in void's runit's core services, 05-misc.sh set's the hostname and timezone.
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
