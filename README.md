```
sudo apt-get install dosfstools e2fsprogs
```

# Passaggi
Determinare la dimensione delle partizioni:

Supponiamo di avere le directory bootfs e rootfs pronte e riempite con i file necessari.

Calcolare la dimensione necessaria per l'immagine

Determina la dimensione delle due partizioni con i seguenti comandi:

```
du -sh bootfs
du -sh rootfs
```

Aggiungi un po' di spazio extra per il filesystem:

```
bootfs_size=$(du -s bootfs | cut -f1)
rootfs_size=$(du -s rootfs | cut -f1)
```
## Aggiungere un po' di spazio extra, ad esempio 100MB per boot e 1GB per root
```
bootfs_size=$((bootfs_size + 100*1024))
rootfs_size=$((rootfs_size + 1024*1024))
```

## Creare un file immagine vuoto

Calcoliamo la dimensione totale dell'immagine e creiamo un file immagine:

```
img_size=$((bootfs_size + rootfs_size))
dd if=/dev/zero of=raspberry_pi.img bs=1K count=$img_size
```

## Creare le partizioni nell'immagine

Usando fdisk, crea due partizioni: una per bootfs e una per rootfs.

```
parted raspberry_pi.img --script -- mklabel msdos
parted raspberry_pi.img --script -- mkpart primary fat32 1MiB $((bootfs_size / 1024 + 1))MiB
parted raspberry_pi.img --script -- mkpart primary ext4 $((bootfs_size / 1024 + 1))MiB 100%
```

## Formattare le partizioni

Mappa l'immagine in dispositivi di loop:

```
losetup -f --show raspberry_pi.img
```
Supponiamo che il dispositivo di loop sia /dev/loop0. Creiamo i dispositivi di loop per le partizioni:

```
losetup -f --show -o $((1*1024*1024)) --sizelimit $((bootfs_size*1024)) raspberry_pi.img
losetup -f --show -o $((bootfs_size*1024 + 1*1024*1024)) raspberry_pi.img
```

## Formattiamo le partizioni (supponiamo che le partizioni siano /dev/loop1 per bootfs e /dev/loop2 per rootfs):

```
mkfs.vfat /dev/loop1
mkfs.ext4 /dev/loop2
```

## Copiare i file nelle partizioni

## Monta le partizioni temporaneamente e copia i file:
```
mkdir -p /mnt/bootfs /mnt/rootfs
mount /dev/loop1 /mnt/bootfs
mount /dev/loop2 /mnt/rootfs

cp -r bootfs/* /mnt/bootfs/
cp -r rootfs/* /mnt/rootfs/

umount /mnt/bootfs /mnt/rootfs
```
## Smontare i dispositivi di loop
```
losetup -d /dev/loop1
losetup -d /dev/loop2
losetup -d /dev/loop0
```
