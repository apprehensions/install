[ $PLAT = pc ] && pacman --noconfirm -Sy nvidia nvidia-utils lib32-nvidia-utils
[ $PLAT = lp ] && sed -i '7s/()/(i915)/' /etc/mkinitcpio.conf


