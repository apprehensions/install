sed -i '82s/. //' /etc/sudoers
useradd -mG wheel,audio,video,kvm,storage -s /bin/zsh wael
passwd && passwd wael
[ $HOST = lp-ao ] && sed -i "/GETTY_ARGS=/s/\"$/ --autologin wael&/" /etc/runit/sv/agetty-tty1/conf
