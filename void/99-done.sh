#!/usr/bin/env bash
source ../vars.conf
set -xe

# install nonfree, multilib, nonfree multilib repos under /mnt
xbps-install -Sy -r /mnt -R $REPO/current void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree

# xbps set repo
mkdir -p /mnt/etc/xbps.d
cp /mnt/usr/share/xbps.d/*-repository-*.conf /mnt/etc/xbps.d/
sed -i "s|https://alpha.de.repo.voidlinux.org|$REPO|g" /mnt/etc/xbps.d/*-repository-*.conf

# reconfigure all packages under /mnt
xbps-reconfigure -r /mnt -fa

# update under /mnt
xbps-install -Syuv -r /mnt
