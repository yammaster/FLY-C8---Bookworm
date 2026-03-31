#!/bin/bash
set -e

echo "======================================================"
echo " Klipper Performance Optimizer für Debian Trixie"
echo " (für FlyOS/Fly-C8 Hybrid-Systeme mit Fly-Kernel)"
echo "======================================================"

### CPU GOVERNOR ###
echo "[1/8] CPU Governor auf performance setzen..."
apt install -y cpufrequtils
echo 'GOVERNOR="performance"' > /etc/default/cpufrequtils
systemctl restart cpufrequtils || true

### PYTHON ###
echo "[2/8] Python 3.12 Virtualenv für Klipper & Moonraker einrichten..."
apt install -y python3.12 python3.12-venv python3-pip

# Klipper venv
echo "[Klipper] Virtualenv aktualisieren..."
su -c "
cd ~/klipper || exit 0
python3.12 -m venv ~/klippy-env
~/klippy-env/bin/pip install -r ~/klipper/scripts/klippy-requirements.txt
" fly

# Moonraker venv
echo "[Moonraker] Virtualenv aktualisieren..."
su -c "
cd ~/moonraker || exit 0
python3.12 -m venv ~/moonraker-env
~/moonraker-env/bin/pip install -r ~/moonraker/scripts/moonraker-requirements.txt
" fly

### SYSTEMD ###
echo "[3/8] systemd optimieren (Klipper Boot-Race verhindern)..."

cat <<EOF >/etc/systemd/system/klipper.service.d/override.conf
[Unit]
After=network-online.target
Wants=network-online.target
EOF

cat <<EOF >/etc/systemd/system/moonraker.service.d/override.conf
[Unit]
After=klipper.service network-online.target
Wants=network-online.target
EOF

systemctl daemon-reload

### TMPFS ###
echo "[4/8] Performance-Boost: tmpfs für Logs aktivieren..."
echo "tmpfs /var/log tmpfs defaults,noatime,size=100M 0 0" >> /etc/fstab

### I/O ###
echo "[5/8] SD‑Card / eMMC I/O optimieren..."
echo "vm.swappiness=10" >> /etc/sysctl.conf
echo "vm.dirty_ratio=5" >> /etc/sysctl.conf
echo "vm.dirty_background_ratio=2" >> /etc/sysctl.conf
sysctl -p

### NETWORK ###
echo "[6/8] NetworkManager optimieren..."
systemctl enable NetworkManager
systemctl restart NetworkManager

### MOONRAKER ###
echo "[7/8] Moonraker Services neu starten..."
systemctl restart klipper || true
systemctl restart moonraker || true

### FERTIG ###
echo "[8/8] Optimierungen abgeschlossen!"
echo "Bitte neu starten: sudo reboot"
