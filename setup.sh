#!/data/data/com.termux/files/usr/bin/bash
# GhostToolkit v1.0 — dependency installer (Kali Linux + Termux)

if [ -d "/data/data/com.termux" ]; then
  echo "[*] Environment: Termux"
  pkg update -y && pkg upgrade -y
  pkg install -y nmap python3 curl whois iproute2 openssl net-tools termux-api zip unzip git
elif grep -qi kali /etc/os-release 2>/dev/null; then
  echo "[*] Environment: Kali Linux"
  sudo apt update
  sudo apt install -y nmap python3 curl whois iproute2 openssl net-tools zip unzip git
else
  echo "[*] Environment: Generic Linux"
  sudo apt update
  sudo apt install -y nmap python3 curl whois openssl zip unzip git
fi

echo "[+] Done! Now run: chmod +x ghosttool.sh && ./ghosttool.sh"
