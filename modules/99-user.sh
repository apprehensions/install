sed -i '82s/. //' /etc/sudoers
useradd -mG wheel,audio,video,kvm,storage -s /bin/zsh wael
passwd && passwd wael
sed -i "agetty_options=/s/\"$/ --autologin wael --noclear&/" /etc/conf.d/agetty.tty1
