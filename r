 Image von externer SD loop‑mounten
(bleibt exakt wie beschrieben, das hast du verstanden ✅)
Shell

sudo losetup -fP --read-only /mnt/image_sd/DEIN_IMAGE.img
sudo mount -o ro /dev/loop0p1 /mnt/image_root

2️⃣ M2WE als Ziel verwenden (per USB, OK)
(Bezeichnung bitte bei dir prüfen!)
Shell

lsblk
Angenommen:
DEV  SIZE  MODEL
sdb  32G   USB Adapter   ← M2WE

Dann:
Shell

sudo parted /dev/sdb --script \  
mklabel msdos \  
mkpart primary ext4 1MiB 100%
sudo mkfs.ext4 /dev/sdb1
sudo mount /dev/sdb1 /mnt/emmc_root``

3️⃣ RootFS aus dem Image übertragen ✅

sudo rsync -aAXH \  
--exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*"} \  
/mnt/image_root/ /mnt/emmc_root/
sync

4️⃣ extlinux.conf jetzt schon richtig vorbereiten
(sehr wichtig!)
Shell

sudo nano /mnt/emmc_root/boot/extlinux/extlinux.conf


👉 Hier NICHT „sdb1“ eintragen, sondern das spätere interne Device:
Plain Text

APPEND root=/dev/mmcblk0p1 rootwait rw

Warum?
sdb = USB (nur jetzt!)
mmcblk0 = eMMC, wenn intern


5️⃣ initramfs aktualisieren
Shell

sudo chroot /mnt/emmc_root
update-initramfs -u
exit

6️⃣ Bootloader auf die M2WE schreiben (JETZT!)
Auch per USB‑Adapter korrekt:
Shell

sudo dd if=/usr/lib/u-boot-sunxi-with-spl.bin of=/dev/sdb bs=1024 seek=8 conv=fsyncsync

✅ Das landet exakt dort, wo der H5 später sucht.
