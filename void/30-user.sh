#!/usr/bin/env bash
source ../vars.conf
set -xe

# make user
useradd -R /mnt -mG $USER_GROUPS -s /bin/zsh wael

# set password
echo "wael:$USERPASSWD" | chpasswd -R /mnt -c SHA512

# autologin
sed -i "/GETTY_ARGS=/s/\"$/ --autologin wael&/" /mnt/etc/sv/agetty-tty1/conf

# doas
xbps-install -R /mnt opendoas
cat > /mnt/etc/doas.conf << EOCONF
permit wael
permit persist wael
EOCONF

# doasedit
curl https://raw.githubusercontent.com/AN3223/scripts/master/doasedit -o /mnt/usr/bin/doasedit
chmod +x /mnt/usr/bin/doasedit
