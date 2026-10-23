#!/data/data/com.termux/files/usr/bin/bash
# GhostToolkit v1.0 — Kali Linux + Termux pentest recon framework
# Author: Naseem | Use ONLY on systems you own or have written permission to test.

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
OUTDIR="ghost_results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"

detect_env() {
  if [ -d "/data/data/com.termux" ]; then echo "termux"
  elif grep -qi kali /etc/os-release 2>/dev/null; then echo "kali"
  else echo "linux"; fi
}
ENV=$(detect_env)
require() { command -v "$1" >/dev/null 2>&1 || { echo -e "${RED}[!] Missing: $1 — run setup first${NC}"; return 1; }; }

banner() {
  echo -e "${CYAN}"
  cat <<'EOF'
   _______  _  __ _______  _  _______ __   __
  |__   __|| || ||__   __|| || |  ___  |\ \ / /
     | |   | || |   | |   | || | |   | | \ V /
     | |   | || |   | |   | || | |   | |  | |
     | |   | || |   | |   | || | |___| |  | |
     | |   | || |   | |   | |_||_____||  |_|
        G H O S T T O O L K I T  v1.0
EOF
  echo -e "${NC}Environment: ${GREEN}$ENV${NC} | Output: $OUTDIR/"
}

pause() { echo; read -rp "Press [Enter] to return to menu... "; }

# ---------- MODULE 1: Full-port recon ----------
m1_recon() {
  read -rp "Target (IP/domain): " TGT
  [ -z "$TGT" ] && return
  F="$OUTDIR/recon_${TGT}.txt"
  echo -e "${YELLOW}[*] Host discovery...${NC}"
  nmap -sn "$TGT" | tee "$F"
  echo -e "${YELLOW}[*] Full TCP scan — all 65,535 ports...${NC}"
  nmap -p- -T4 --open "$TGT" >> "$F"
  PORTS=$(grep -oE '^[0-9]+/tcp' "$F" | cut -d/ -f1 | sort -un | tr '\n' ',' | sed 's/,$//')
  if [ -n "$PORTS" ]; then
    echo -e "${YELLOW}[*] Service/version detection on: $PORTS${NC}"
    nmap -sV -p "$PORTS" "$TGT" >> "$F"
  fi
  echo -e "${GREEN}[+] Saved: $F${NC}"
  pause
}

# ---------- MODULE 2: Subdomain enumerator ----------
m2_subdomains() {
  read -rp "Domain (e.g. example.com): " DOM
  [ -z "$DOM" ] && return
  F="$OUTDIR/subs_${DOM}.txt"
  echo -e "${YELLOW}[*] Passive enumeration via crt.sh...${NC}"
  curl -s "https://crt.sh/?q=%25.${DOM}&output=json" \
    | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    names = sorted({e['common_name'] for e in data} | {n for e in data for n in e.get('name_value','').split('\n')})
    for n in names: print(n)
except Exception: pass" | grep -i "$DOM" | sort -u > "$F"
  COUNT=$(wc -l < "$F")
  echo -e "${GREEN}[+] Found $COUNT unique subdomains -> $F${NC}"
  read -rp "Resolve them live? (y/N): " ANS
  if [[ "$ANS" == "y" ]]; then
    while read -r sub; do
      IP=$(getent hosts "$sub" 2>/dev/null | awk '{print $1}' | head -1)
      [ "$ENV" = "termux" ] && IP=$(nslookup "$sub" 2>/dev/null | awk '/^Address/{print $2}' | tail -1)
      [ -n "$IP" ] && echo -e "${GREEN}[+]${NC} $sub -> $IP"
    done < "$F"
  fi
  pause
}

# ---------- MODULE 3: Directory brute-forcer ----------
m3_dirs() {
  read -rp "Target URL (e.g. https://site.com/): " URL
  read -rp "Wordlist path (blank = built-in): " WL
  TMPWL="$OUTDIR/.words.txt"
  [ -z "$WL" ] && cat > "$TMPWL" <<'EOF'
admin
login
dashboard
backup
config
uploads
api
wp-admin
phpmyadmin
.git
.env
secret
test
old
tmp
data
EOF
  WORDS="${WL:-$TMPWL}"
  echo -e "${YELLOW}[*] Brute-forcing directories...${NC}"
  while read -r dir; do
    CODE=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 5 "${URL%/}/$dir")
    case "$CODE" in
      200|301|302|403) echo -e "${GREEN}[${CODE}]${NC} /$dir" ;;
    esac
  done < "$WORDS"
  pause
}

# ---------- MODULE 4: Banner grabber ----------
m4_banner() {
  read -rp "Target host: " HOST
  read -rp "Ports (comma-separated, blank = 21,22,25,80,443): " PLIST
  PLIST="${PLIST:-21,22,25,80,443}"
  IFS=',' read -ra ARR <<< "$PLIST"
  for P in "${ARR[@]}"; do
    B=$(timeout 3 bash -c "echo '' | openssl s_client -connect $HOST:$P 2>/dev/null | head -1" \
        || timeout 3 bash -c "exec 3<>/dev/tcp/$HOST/$P && head -c 128 <&3" 2>/dev/null)
    [ -n "$B" ] && echo -e "${GREEN}[$P]${NC} $B" || echo -e "${RED}[$P]${NC} no banner"
  done
  pause
}

# ---------- MODULE 5: WHOIS / info gathering ----------
m5_whois() {
  read -rp "Domain: " DOM
  F="$OUTDIR/whois_${DOM}.txt"
  whois "$DOM" | tee "$F"
  echo -e "${GREEN}[+] Saved: $F${NC}"
  pause
}

# ---------- MODULE 6: Hash toolkit ----------
m6_hash() {
  echo -e "${CYAN}1.${NC} Identify hash type   ${CYAN}2.${NC} MD5/SHA wordlist crack"
  read -rp "Choose: " HC
  if [ "$HC" = "1" ]; then
    read -rp "Paste hash: " H
    python3 - "$H" <<'PY'
import sys, re, hashlib
h = sys.argv[1].strip()
lens = {32:["MD5","NTLM"], 40:["SHA1"], 56:["SHA224"], 64:["SHA256"],
        96:["SHA384"], 128:["SHA512"]}
if not re.fullmatch(r'[a-fA-F0-9]+', h):
    print("[!] Not pure hex — could be bcrypt/other")
else:
    print(f"[*] Length {len(h)} -> likely: {', '.join(lens.get(len(h), ['unknown']))}")
PY
  elif [ "$HC" = "2" ]; then
    read -rp "Hash: " H; read -rp "Wordlist (blank = built-in): " WL
    TMPWL="$OUTDIR/.dict.txt"
    [ -z "$WL" ] && printf 'password\n123456\nqwerty\nadmin\nletmein\nroot\ntoor\nkali\ntermux\nnaseem\n' > "$TMPWL"
    python3 - "$H" "${WL:-$TMPWL}" <<'PY'
import sys, hashlib
target, wl = sys.argv[1], sys.argv[2]
algos = [hashlib.md5, hashlib.sha1, hashlib.sha256, hashlib.sha512]
for line in open(wl, errors='ignore'):
    w = line.strip()
    for a in algos:
        if a(w.encode()).hexdigest() == target.lower():
            print(f"[+] CRACKED: '{w}' ({a().name})"); sys.exit(0)
print("[-] No match in wordlist.")
PY
  fi
  pause
}

# ---------- MODULE 7: IP / network utilities ----------
m7_netinfo() {
  echo -e "${CYAN}[*] Local interfaces:${NC}"; ip -brief addr 2>/dev/null || ifconfig
  echo -e "${CYAN}[*] Public IP:${NC}"; curl -s ifconfig.me; echo
  echo -e "${CYAN}[*] Default gateway:${NC}"; ip route 2>/dev/null | grep default
  echo -e "${CYAN}[*] DNS:${NC}"; cat /etc/resolv.conf 2>/dev/null | grep nameserver
  if [ "$ENV" = "termux" ]; then
    echo -e "${CYAN}[*] WiFi info (termux-api):${NC}"
    command -v termux-wifi-connectioninfo >/dev/null && termux-wifi-connectioninfo
  fi
  pause
}

# ---------- MODULE 8: Live host sweeper ----------
m8_sweep() {
  read -rp "CIDR network (e.g. 192.168.1.0/24): " NET
  [ -z "$NET" ] && return
  F="$OUTDIR/sweep_${NET//\//_}.txt"
  echo -e "${YELLOW}[*] Sweeping $NET ...${NC}"
  nmap -sn -T4 "$NET" | tee "$F"
  UP=$(grep -c "Host is up" "$F")
  echo -e "${GREEN}[+] $UP hosts up -> $F${NC}"
  pause
}

# ---------- MENU ----------
while true; do
  clear; banner
  echo " ─────────────────────────────────────────"
  echo -e "  ${CYAN}1.${NC} Full-port recon (all 65,535 TCP)"
  echo -e "  ${CYAN}2.${NC} Subdomain enumerator"
  echo -e "  ${CYAN}3.${NC} Directory brute-forcer"
  echo -e "  ${CYAN}4.${NC} Banner grabber"
  echo -e "  ${CYAN}5.${NC} WHOIS info gathering"
  echo -e "  ${CYAN}6.${NC} Hash toolkit (identify + crack)"
  echo -e "  ${CYAN}7.${NC} Network info / local IP"
  echo -e "  ${CYAN}8.${NC} Live host sweeper"
  echo -e "  ${CYAN}0.${NC} Exit"
  echo " ─────────────────────────────────────────"
  read -rp "Select module: " CHOICE
  case "$CHOICE" in
    1) require nmap && m1_recon ;;
    2) require curl && m2_subdomains ;;
    3) require curl && m3_dirs ;;
    4) m4_banner ;;
    5) require whois && m5_whois ;;
    6) m6_hash ;;
    7) m7_netinfo ;;
    8) require nmap && m8_sweep ;;
    0) echo -e "${GREEN}[+] Results in $OUTDIR/${NC}"; exit 0 ;;
    *) echo -e "${RED}[!] Invalid choice${NC}"; sleep 1 ;;
  esac
done
