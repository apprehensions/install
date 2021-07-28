sed -i '33s/.//' /etc/pacman.conf
sed -i -e '37s/.//' -e '37s/5/12/' /etc/pacman.conf
sed -i '93,94s/.//' /etc/pacman.conf
echo -e "\n[extra]\nInclude = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
echo -e "\n[community]\nInclude = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
pacman --noconfirm -Sy wget git zsh exa zsh-synatx-highlighting artix-archlinux-support
git clone https://aur.archlinux.org/paru-bin.git /usr/src/paru-bin && chmod 777 /usr/src/paru-bin
