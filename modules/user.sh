sed -i '82s/. //' /etc/sudoers
useradd -mG wheel,audio,video,kvm,storage -s /bin/zsh wael
passwd && passwd wael
