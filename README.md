# homelab-pi5

A fully featured home server built on a Raspberry Pi 5 (8GB RAM), running 24/7 with automated monitoring, backups, and Telegram-based remote control.

## Hardware

- **Compute:** Raspberry Pi 5 8GB with official active cooler
- **Storage:**
  - WD Red Pro 4TB NAS HDD (main storage)
  - SanDisk Extreme SSD 1TB (media server)
  - WD My Book 3TB (backup)
- **Networking:** Ethernet, Tailscale VPN
- **Powered USB Hub:** UNITEK Y-3089 (for SSD power stability)
- **Cooling:** Laptop cooler zip tied to mesh enclosure

## Software Stack

| Service | Method | Purpose |
|---|---|---|
| Jellyfin | Docker | Media server |
| Pi-hole | Docker | Network-wide ad blocking |
| Nextcloud | Snap | Personal cloud storage |
| Samba | Native | Network file sharing |
| Tailscale | Native | Secure remote access |

## Features

### Telegram Bot Commands

```
/ping        — Check if Pi is alive
/temp        — CPU + drive temperatures
/uptime      — Uptime and load average
/ram         — RAM usage
/status      — Drive capacity and usage
/health      — SMART health for all drives
/speedtest   — Internet speed test
/containers  — Docker container status
/logs        — Last 10 lines of backup log
/ip          — Local and Tailscale IP
/piinfo      — Pi model and OS info
/backup      — Trigger manual backup
/restart     — Reboot Pi (15 sec delay, cancellable)
/shutdown    — Shutdown Pi (15 sec delay, cancellable)
/news        — Latest F1, Aerospace and General news
/quote       — Random motivational quote
/commands    — Show all available commands
```

### Automatic Alerts
- 💤 Pi came back online — instant on boot
- 🌡️ Drive temp above 55°C
- 🔥 CPU above 75°C
- 📊 High CPU load
- 💾 Any drive above 80% full
- ❌ Drive not mounted
- ❌ Jellyfin container down
- 📅 Backup overdue 8+ days
- 🚨 Failed SSH login attempts
- 🌐 New Tailscale device detected

### Automated Schedule
```
1:00 AM Friday  — Auto backup
4:00 AM daily   — Morning motivation quote
5:00 AM daily   — Daily news (F1, Aerospace, General)
Every 5 mins    — System monitoring
```

## Scripts

| Script | Purpose |
|---|---|
| `telegram-bot.sh` | Main bot — handles all commands |
| `monitor.sh` | Automatic alerts every 5 mins |
| `backup-nas.sh` | Weekly backup with Telegram notification |
| `morning-motivation.sh` | Daily motivational quote |
| `news-alert.sh` | Daily news digest |

## Setup

### Prerequisites
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install docker.io docker-compose samba smartmontools curl python3 -y
```

### Jellyfin
```bash
sudo mkdir -p /opt/jellyfin
sudo nano /opt/jellyfin/docker-compose.yml
sudo docker compose -f /opt/jellyfin/docker-compose.yml up -d
```

### Pi-hole
```bash
sudo mkdir -p /opt/pihole
sudo nano /opt/pihole/docker-compose.yml
sudo docker compose -f /opt/pihole/docker-compose.yml up -d
```

### Nextcloud
```bash
sudo snap install nextcloud
```

### Telegram Bot
```bash
sudo cp scripts/* /usr/local/bin/
sudo chmod +x /usr/local/bin/*.sh
sudo cp services/* /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable telegram-bot pi-online-notify
sudo systemctl start telegram-bot
```

### Crontab
```
*/5 * * * *  /usr/local/bin/monitor.sh
0 1 * * 5    /usr/local/bin/backup-nas.sh
0 4 * * *    /usr/local/bin/morning-motivation.sh
0 5 * * *    /usr/local/bin/news-alert.sh
```

## Architecture

```
Internet
    │
Tailscale VPN
    │
Raspberry Pi 5
    ├── Docker
    │   ├── Jellyfin (port 8096)
    │   └── Pi-hole (port 8080, 53)
    ├── Nextcloud Snap
    ├── Samba
    └── Storage
        ├── /mnt/nas-hdd    (WD Red Pro 4TB)
        ├── /mnt/media-ssd  (SanDisk SSD 1TB)
        └── /mnt/storage    (WD My Book 3TB)
```

## Access URLs

```
Jellyfin:   http://<YOUR_TAILSCALE_IP>:8096
Pi-hole:    http://<YOUR_TAILSCALE_IP>:8080/admin
Nextcloud:  http://<YOUR_TAILSCALE_IP>/
Samba:      \\<YOUR_TAILSCALE_IP>\<share-name>
```

## Performance

- **Network:** 926 Mbps down / 925 Mbps up
- **Drive Transfer:** 145-152 MB/s direct rsync
- **Idle Temps:** CPU 50°C, NAS HDD 41°C, SSD 35°C
- **RAM Usage:** ~884MB of 7.8GB

## Notes

- All services survive reboot via systemd and Docker restart policies
- Tailscale used for all remote access — no ports exposed to internet
- Pi-hole DNS routed through Tailscale for all connected devices
- UAS quirks mode enabled for SSD stability

## Author

Jainil Solanki — Aerospace Engineer
- Instagram: [@jainil_solanki786](https://instagram.com/jainil_solanki786)
