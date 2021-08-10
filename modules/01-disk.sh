mkfs.vfat -nBOOP -F32 $ESP
mkfs.btrfs -L root -f $ROOT
mount -o $BTRFS_OPTS $ROOT /mnt
btrfs subvolume create /mnt/@
btrfs subvolume set-default /mnt/@
umount /mnt
mount -o $BTRFS_OPTS,subvol=@ $ROOT /mnt
