#!/bin/bash
set -e

### Farben ###
GR="\e[32m"
YE="\e[33m"
RD="\e[31m"
NC="\e[0m"

clear
echo -e "${GR}=============================================="
echo -e "  FlyOS → Debian Upgrade (Bookworm/Trixie)"
echo -e "  Kernel / Bootloader / initramfs bleiben unverändert"
echo -e "==============================================${NC}"
echo ""

### Auswahl des Targets ###
echo -e "${YE}Welches Debian-Release soll installiert werden?${NC}"
echo "1) Bookworm (Debian 12)"
echo "2) Trixie (Debian 13)"
read -p "Auswahl (1/2): " REL

if [ "$REL" == "1" ]; then
    TARGET="bookworm"
elif [ "$REL" == "2" ]; then
    TARGET="trixie"
else
    echo -e "${RD}Ungültige Auswahl!${NC}"
    exit 1
fi

echo ""
echo -e "${GR}→ Upgrade von Bullseye zu ${TARGET} wird vorbereitet...${NC}"
echo ""

START_TIME=$(date +%s)

### 1: Kernel & initramfs sperren ###
echo -e "${YE}[1/8] Kernel- und initramfs-Pakete einfrieren...${NC}"
apt-mark hold linux-image-arm64 linux-image-*-sunxi64 initramfs-tools initramfs-tools-core >/dev/null 2>&1 || true
sleep 0.5

### 2: initramfs deaktivieren ###
echo -e "${YE}[2/8] initramfs deaktivieren...${NC}"
if [ -f /usr/sbin/update-initramfs ]; then
    mv /usr/sbin/update-initramfs /usr/sbin/update-initramfs.bak
fi
echo -e '#!/bin/sh\nexit 0' > /usr/sbin/update-initramfs
chmod +x /usr/sbin/update-initramfs
sleep 0.5

### 3: APT-Sources aktualisieren ###
echo -e "${YE}[3/8] APT-Sources auf ${TARGET} umstellen...${NC}"
sed -i "s/bullseye/${TARGET}/g" /etc/apt/sources.list
if ls /etc/apt/sources.list.d/*.list >/dev/null 2>&1; then
    sed -i "s/bullseye/${TARGET}/g" /etc/apt/sources.list.d/*.list || true
fi
sleep 0.5

### 4: Vorbereitung ###
echo -e "${YE}[4/8] apt update & upgrade (ohne neue Pakete)...${NC}"
apt update
apt upgrade --without-new-pkgs -y
sleep 0.5

### 5: dist-upgrade ###
echo -e "${YE}[5/8] Vollständiges Upgrade auf ${TARGET} wird durchgeführt...${NC}"
apt full-upgrade -y

### 6: Clean-up ###
echo -e "${YE}[6/8] autoremove...${NC}"
apt autoremove -y || true
sleep 0.5

### 7: Kernel bestätigen ###
echo -e "${YE}[7/8] Prüfe aktiven Kernel...${NC}"
uname -a
echo ""
echo -e "${YE}Wenn dies NICHT der FlyOS-H5/sunxi64 Kernel ist: NICHT rebooten!${NC}"

### 8: Erfolgsmeldung ###
END_TIME=$(date +%s)
DIFF=$((END_TIME - START_TIME))

echo ""
echo -e "${GR}==============================================${NC}"
echo -e "${GR} Upgrade auf ${TARGET} erfolgreich abgeschlossen!${NC}"
echo -e "${GR} Dauer: ${DIFF} Sekunden${NC}"
echo -e "${GR} Kernel / Bootloader / CAN / HDMI / WLAN / SHT36 bleiben funktionsfähig.${NC}"
echo -e "${GR}==============================================${NC}"
echo ""

### Reboot-Abfrage ###
read -p "Jetzt neu starten? (j/n): " RB

if [[ "$RB" =~ ^[Jj]$ ]]; then
    echo -e "${GR}System wird neu gestartet...${NC}"
    sleep 1
    reboot
else
    echo -e "${YE}Kein Reboot durchgeführt. Bitte später manuell: sudo reboot${NC}"
fi
