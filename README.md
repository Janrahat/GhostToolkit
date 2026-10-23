# GhostToolkit v1.0

Menu-driven security recon framework for **Kali Linux** and **Termux (Android)**.
Auto-detects the environment and saves all results to a timestamped `ghost_results_*` folder.

## Files
- `ghosttool.sh` — main toolkit (8 modules, menu-driven)
- `setup.sh` — dependency installer (Termux + Kali)

## Install (Termux)
```bash
pkg update -y && pkg install -y git
chmod +x setup.sh ghosttool.sh
./setup.sh
./ghosttool.sh
```

## Install (Kali Linux)
```bash
chmod +x setup.sh ghosttool.sh
sudo ./setup.sh
./ghosttool.sh
```

## Modules
| # | Module | Method |
|---|--------|--------|
| 1 | Full-port recon | `nmap -p-` scans ALL 65,535 TCP ports + service detection |
| 2 | Subdomain enumerator | Passive via crt.sh + live DNS resolution |
| 3 | Directory brute-forcer | Status filtering (200/301/302/403), built-in or custom wordlist |
| 4 | Banner grabber | OpenSSL TLS + raw /dev/tcp fallback |
| 5 | WHOIS gathering | Full registrar/DNS record dump |
| 6 | Hash toolkit | Length-based type ID + MD5/SHA1/SHA256/SHA512 wordlist cracking |
| 7 | Network info | Interfaces, public IP, gateway, DNS, Termux WiFi API |
| 8 | Live host sweeper | CIDR ping sweep with live-host count |

## Legal
Use ONLY on systems you own or have explicit written authorization to test.
Unauthorized scanning is illegal in most jurisdictions.
