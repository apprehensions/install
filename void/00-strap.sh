#!/usr/bin/env bash
source ../../vars.conf
set -xe

# strap void linux with $VOID_PACKAGES and use $REPO as the primary source of packages
XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO/current" ${VOID_PACKAGES[@]}
