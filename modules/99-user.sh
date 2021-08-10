sed -i '82s/. //' /etc/sudoers
useradd -mG wheel,audio,video,kvm,storage -s /bin/zsh wael
passwd && passwd wael

[ $DIST = artix ] && sed -i "agetty_options=/s/\"$/ --autologin wael --noclear&/" /etc/conf.d/agetty.tty1
[ $DIST = arch ] && mkdir /etc/systemd/system/getty@tty1.service.d && echo -e "[Service]\nExecStart=\nExecStart=-/usr/bin/agetty --noissue --autologin wael --noclear" > /etc/systemd/system/getty@tty1.service.d/override.conf
