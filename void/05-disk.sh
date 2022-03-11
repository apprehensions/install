#!/usr/bin/env bash
source ../vars.conf
set -xe

# mount for chroot
mount --rbind /sys /mnt/sys && mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev && mount --make-rslave /mnt/dev
mount --rbind /proc /mnt/proc && mount --make-rslave /mnt/proc

# set fstab
curl https://gitlab.com/-/snippets/2232559/raw/main/bash -o /mnt/usr/bin/genfstab
chmod +x /mnt/usr/bin/genfstab
/mnt/usr/bin/genfstab -U /mnt >> /mnt/etc/fstab
