#!/bin/bash

# creazione di partizione per uboot

# https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/msd.md


# calculate the size of the image

bootfs_size=$(du -s bootfs | cut -f1)
#rootfs_size=$(du -s /home/eggs/.mnt/filesystem.squashfs/ | cut -f1)
rootfs_size=$(du -s rootfs/ | cut -f1)

echo "bootfs size: $bootfs_size"
echo "rootfs size: $rootfs_size"

# add some extra space to the bootfs and rootfs
bootfs_size=$((bootfs_size + 100*1024))
rootfs_size=$((rootfs_size + 1024*1024))

# create an empty image file
img_size=$((bootfs_size + rootfs_size))
dd if=/dev/zero of=raspberry_pi.img bs=1K count=$img_size

# create two partitions: one for bootfs and one for rootfs
parted raspberry_pi.img --script -- mklabel msdos
parted raspberry_pi.img --script -- mkpart primary fat32 1MiB $((bootfs_size / 1024 + 1))MiB
parted raspberry_pi.img --script -- mkpart primary ext4 $((rootfs_size / 1024 + 1))MiB 100%

# Formattare le partizioni
losetup -f --show raspberry_pi.img
# Supponiamo che il dispositivo di loop sia /dev/loop0. 
# Creiamo i dispositivi di loop per le partizioni:
losetup -f --show -o $((1*1024*1024)) --sizelimit $((bootfs_size*1024)) raspberry_pi.img
losetup -f --show -o $((bootfs_size*1024 + 1*1024*1024)) raspberry_pi.img

#Formattiamo le partizioni (supponiamo che le partizioni siano /dev/loop1 per bootfs e /dev/loop2 per rootfs):

mkfs.vfat /dev/loop1
mkfs.ext4 /dev/loop2


# Montare le partizioni e copia i file:
mkdir -p /mnt/bootfs /mnt/rootfs
mount /dev/loop1 /mnt/bootfs
mount /dev/loop2 /mnt/rootfs
cp -r bootfs/* /mnt/bootfs/
cp -r rootfs/* /mnt/rootfs/
# smontare le partizioni
umount /mnt/bootfs /mnt/rootfs

# Smontare i dispositivi di loop
losetup -d /dev/loop1
losetup -d /dev/loop2
losetup -d /dev/loop0

