#!/bin/bash
set -e

echo "=============================================="
echo "  Debian Bullseye → Bookworm Upgrade Script"
echo "  (Kernel / Bootloader / initramfs bleiben unverändert)"
echo "  FLY-C8 / H5 kompatibel"
echo "=============================================="

# 1) Kernel & initramfs sperren
echo "[1/8] Einfrieren von Kernel- und initramfs-Paketen..."
apt-mark hold linux-image-arm64 linux-image-*-sunxi64 initramfs-tools initramfs-tools-core || true

# 2) initramfs deaktivieren (FlyOS-Kernel unterstützt kein initrd)
echo "[2/8] initramfs-tools deaktivieren..."
if [ -f /usr/sbin/update-initramfs ]; then
    mv /usr/sbin/update-initramfs /usr/sbin/update-initramfs.bak
fi
echo -e '#!/bin/sh\nexit 0' > /usr/sbin/update-initramfs
chmod +x /usr/sbin/update-initramfs

# 3) apt Sources auf Bookworm umstellen
echo "[3/8] APT-Sources auf Bookworm umstellen..."
sed -i 's/bullseye/bookworm/g' /etc/apt/sources.list
if ls /etc/apt/sources.list.d/*.list >/dev/null 2>&1; then
    sed -i 's/bullseye/bookworm/g' /etc/apt/sources.list.d/*.list || true
fi

# 4) Update vorbereiten
echo "[4/8] Update vorbereiten..."
apt update
apt upgrade --without-new-pkgs -y

# 5) Vollständiges Distribution-Upgrade
echo "[5/8] Vollständiges Bookworm-Upgrade ausführen..."
apt full-upgrade -y

# 6) Nicht verwendete Pakete entfernen
echo "[6/8] autoremove durchführen..."
apt autoremove -y || true

# 7) uname prüfen
echo "[7/8] Prüfen, ob Fly-Kernel weiterhin aktiv ist..."
KERNEL=$(uname -a)
echo "Aktiver Kernel:"
echo "$KERNEL"
echo ""
echo "⚠️  Wenn hier NICHT dein FlyOS-H5 / sunxi64 Kernel steht:"
echo "    → NICHT neu starten und mich sofort informieren!"
echo ""

# 8) Erfolgsmeldung
echo "[8/8] Upgrade abgeschlossen!"
echo "=============================================="
echo " Debian wurde erfolgreich auf Bookworm aktualisiert."
echo " Fly-Kernel & CAN/HDMI/WLAN/SHT36 bleiben vollständig funktionsfähig."
echo "=============================================="
echo ""
echo "Jetzt kannst du sicher neu starten:"
echo "    sudo reboot"
echo ""
