# MEGA-RECON — All-in-One Recon Toolkit

> **⚠️ WARNING:** Use ONLY on targets you are explicitly authorized to test
> (your own assets, lab environments, or permitted bug-bounty scopes).
> Unauthorized scanning is illegal under the IT Act 2000 (India), CFAA (US),
> and equivalent laws worldwide.

An all-in-one automated reconnaissance toolkit for **Kali Linux** and
**Termux (Android)**. One script runs the full recon workflow and generates
a consolidated Markdown report.

## Tools Included

| File | Platform | Description |
|------|----------|-------------|
| `mega-recon.sh` | Kali Linux | Full recon: subdomains, all-port nmap, whatweb, wafw00f, waybackurls, gobuster, nikto, report |
| `mega-recon-termux.sh` | Termux | Lightweight: nmap full `-p-` port scan, whatweb, nikto, report |

## Recon Workflow (Kali)

```
subfinder → nmap -p- (all 65,535 ports) → whatweb → wafw00f
        → waybackurls → gobuster → nikto → REPORT.md
```

## Installation & Usage

### Kali Linux

```bash
git clone https://github.com/Janrahat/GhostToolkit.git
cd GhostToolkit
chmod +x mega-recon.sh
./mega-recon.sh example.com
```

Dependencies (nmap, whatweb, nikto, gobuster, subfinder, wafw00f) are
auto-installed on first run if missing.

### Termux (Android)

```bash
pkg install git
git clone https://github.com/Janrahat/GhostToolkit.git
cd GhostToolkit
bash mega-recon-termux.sh example.com
```

Note: Termux runs without root, so nmap automatically uses full TCP
connect scans instead of SYN scans.

## Output

All results are saved to `<domain>-recon-<timestamp>/`, including:

- `subdomains.txt` — discovered subdomains
- `nmap-allports.txt` — full 65,535-port scan (`-p-`)
- `nmap-service-scan.txt` — service/version/script scan on open ports
- `whatweb.txt` — technology fingerprint
- `waf.txt` — WAF detection
- `urls.txt` — historical URLs from Wayback Machine
- `directories.txt` — discovered directories
- `nikto.txt` — web vulnerability findings
- `REPORT.md` — consolidated Markdown report

## Legal Practice Labs

Practice legally on these intentionally vulnerable targets:

- `testphp.vulnweb.com`
- `demo.testfire.net`
- HackTheBox / TryHackMe labs

## License

MIT
