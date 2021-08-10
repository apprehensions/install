# enable pacman colors
sed -i '33s/.//' /etc/pacman.conf

# enable parallel downloads and set it to twelve
sed -i -e '37s/.//' -e '37s/5/12/' /etc/pacman.conf

# enable 32-bit libraries
sed -i '93,94s/.//' /etc/pacman.conf

# artix archlinux repos
if [[ $DIST = artix ]]; then
	pacman --noconfirm -Sy artix-archlinux-support
	echo -e "\n[extra]\nInclude = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
	echo -e "\n[community]\nInclude = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
	echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
fi

# general programs
pacman --noconfirm -Sy wget git zsh exa zsh-syntax-highlighting 

# aur helper
git clone https://aur.archlinux.org/paru-bin.git /usr/src/paru-bin && chmod 777 /usr/src/paru-bin
