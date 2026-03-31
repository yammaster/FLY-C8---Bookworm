#!/bin/bash
set -e

GR="\e[32m"; RD="\e[31m"; YE="\e[33m"; NC="\e[0m"

echo -e "${GR}========================================="
echo -e " FLY‑C8 Automated Health Checker"
echo -e " Kernel / CAN / Klipper / Netzwerk / System"
echo -e "=========================================${NC}"

### KERNEL ###
echo -e "${YE}[1/10] Kernel prüfen...${NC}"
KERNEL=$(uname -a)
echo "$KERNEL"

if [[ "$KERNEL" != *"sunxi"* ]]; then
    echo -e "${RD}❌ WARNUNG: Nicht-Fly Kernel aktiv!${NC}"
else
    echo -e "${GR}✔ Fly-Kernel erkannt.${NC}"
fi

### CAN0 ###
echo -e "${YE}[2/10] CAN0 prüfen...${NC}"
if ip link show can0 >/dev/null 2>&1; then
    echo -e "${GR}✔ can0 Interface vorhanden.${NC}"
    echo "→ Status:"
    ip -details link show can0 || true
else
    echo -e "${RD}❌ kein can0 Interface!${NC}"
fi

### SHT36 TOOLHEAD ###
echo -e "${YE}[3/10] SHT36 Toolhead testen...${NC}"
if cansend can0 123#01020304 2>/dev/null; then
    echo -e "${GR}✔ CAN Sendetest erfolgreich.${NC}"
else
    echo -e "${RD}❌ CAN Sendetest fehlgeschlagen.${NC}"
fi

### NETWORK ###
echo -e "${YE}[4/10] Netzwerk prüfen...${NC}"
nmcli device status || echo -e "${RD}❌ NetworkManager Problem${NC}"

### WLAN ###
echo -e "${YE}[5/10] WLAN (M2-SDIO) prüfen...${NC}"
if iw dev 2>/dev/null | grep Interface; then
    echo -e "${GR}✔ WLAN erkannt.${NC}"
else
    echo -e "${RD}❌ WLAN nicht erkannt.${NC}"
fi

### ETH ###
echo -e "${YE}[6/10] Ethernet prüfen...${NC}"
ethtool eth0 || true

### TEMPERATURE ###
echo -e "${YE}[7/10] CPU Temperatur...${NC}"
vcgencmd measure_temp 2>/dev/null || cat /sys/class/thermal/thermal_zone0/temp

### KLIPPER ###
echo -e "${YE}[8/10] Klipper Status...${NC}"
systemctl is-active klipper && echo -e "${GR}✔ Klipper läuft.${NC}" || echo -e "${RD}❌ Klipper läuft nicht.${NC}"

### MOONRAKER ###
echo -e "${YE}[9/10] Moonraker Status...${NC}"
systemctl is-active moonraker && echo -e "${GR}✔ Moonraker läuft.${NC}" || echo -e "${RD}❌ Moonraker läuft nicht.${NC}"

### USB ###
echo -e "${YE}[10/10] USB Geräte...${NC}"
lsusb

echo -e "${GR}========================================="
echo -e "   Health-Check abgeschlossen"
echo -e "=========================================${NC}"
``
