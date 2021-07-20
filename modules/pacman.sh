sed -i -e '33s/.//' -e '37s/.//' -e '37s/5/12' -e '93,94s/.//' /etc/pacman.conf
echo -e "\n[extra]\ninclude = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
echo -e "\n[community]\ninclude = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
echo -e "\n[multilib]\ninclude = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
