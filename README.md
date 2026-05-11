# Home Media Server

A complete Docker-based media stack with Jellyfin, Radarr, Sonarr, Prowlarr, qBittorrent, Homepage dashboard, and Portainer.

## Requirements

- **OS:** Windows 10/11 (with WSL2) or Linux (Ubuntu/Debian)
- **Software:** Docker Desktop (Windows) or Docker Engine (Linux)
- **Hardware:** Any x86_64 PC with Intel 6th-gen CPU or newer (for hardware transcoding)
- **RAM:** 8GB minimum, 16GB recommended
- **Storage:** SSD for OS/configs + HDD/SSD for media library
- **Network:** Wired Ethernet preferred; Wi-Fi works but less stable for large transfers

## Quick Start

```bash
# 1. Clone or download this repository
# 2. Edit .env with your settings
# 3. Create folders
mkdir -p data/{jellyfin,radarr,sonarr,prowlarr,qbittorrent,portainer}
mkdir -p library/{movies,tv,downloads}

# 4. Start everything
docker compose up -d

# 5. Open http://localhost:3000 (Homepage dashboard)
```

## File Structure

```
.
├── .env                      # Environment variables (IP, API keys, timezone)
├── .gitignore                # Git ignore rules
├── docker-compose.yml        # All services
├── homepage/                 # Homepage dashboard configs (tracked in git)
│   ├── settings.yaml
│   ├── services.yaml
│   ├── widgets.yaml
│   └── docker.yaml
├── data/                     # Persistent container data (gitignored)
│   ├── jellyfin/
│   ├── radarr/
│   ├── sonarr/
│   ├── prowlarr/
│   ├── qbittorrent/
│   └── portainer/
└── library/                  # Media storage (gitignored)
    ├── movies/
    ├── tv/
    └── downloads/
```

## Configuration

### 1. Edit `.env`

This is the only file you must customize before starting.

```env
# Your server's LAN IP (run `ipconfig` on Windows or `hostname -I` on Linux)
SERVER_IP=192.168.1.42

# Homepage security — which Host headers are allowed
HOMEPAGE_ALLOWED_HOSTS=${SERVER_IP}:3000,localhost:3000,127.0.0.1:3000

# Timezone
TZ=Europe/Bratislava

# Linux user IDs (Windows Docker Desktop ignores these; on Linux run `id` and paste values)
PUID=1000
PGID=1000

# --- API Keys & Passwords ---
# You will fill these in AFTER first boot (see "Where to Get API Keys" below)
RADARR_API_KEY=replace_me
SONARR_API_KEY=replace_me
JELLYFIN_API_KEY=replace_me
QBIT_PASSWORD=replace_me
PORTAINER_API_KEY=replace_me
```

**Replace `192.168.1.42` with your actual LAN IP.**

### 2. Start the stack

```bash
docker compose up -d
```

Wait 60 seconds for all containers to initialize.

### 3. Collect API keys

| Service | Where to find the key |
|---------|----------------------|
| **Radarr** | Open http://localhost:7878 → Settings → General → API Key |
| **Sonarr** | Open http://localhost:8989 → Settings → General → API Key |
| **Jellyfin** | Open http://localhost:8096 → Dashboard → Advanced → API Keys → **+** |
| **qBittorrent** | Open http://localhost:8080 → Tools → Options → Web UI → set a password |
| **Portainer** | Open http://localhost:9000 → create admin account → My Account → **+ Add access token** |

### 4. Paste keys into `.env`

Edit `.env` again and replace all `replace_me` values with the real keys/passwords.

### 5. Restart Homepage to pick up new values

```bash
docker restart homepage
```

Now open http://localhost:3000 — you should see live widgets with queue counts, system stats, and quick links.

---

## Step-by-Step Service Setup

### qBittorrent (Download Client)

**URL:** http://localhost:8080

1. Login with default credentials (check `docker logs qbittorrent` for random password, or try `admin` / `adminadmin`)
2. **Tools → Options → Downloads**
   - Default Save Path: `/media/downloads`
   - Keep incomplete torrents in: `/media/downloads/incomplete` (optional)
3. **Tools → Options → Web UI**
   - Enable Web UI
   - Set username and password
   - The password you set here goes into `.env` as `QBIT_PASSWORD`

### Prowlarr (Indexer Manager)

**URL:** http://localhost:9696

1. **Settings → Indexers** → Add your torrent/usenet indexers
2. **Settings → Apps**
   - Add **Radarr**
     - Radarr Server: `radarr` (Docker container name, **not** `localhost`)
     - Port: `7878`
     - API Key: from Radarr settings
   - Add **Sonarr**
     - Sonarr Server: `sonarr` (Docker container name, **not** `localhost`)
     - Port: `8989`
     - API Key: from Sonarr settings

**Why `radarr` and not `localhost`?** Inside Docker, `localhost` means the container itself. Container names act as DNS names on the internal Docker network.

### Radarr (Movie Manager)

**URL:** http://localhost:7878

1. **Settings → Media Management**
   - Root Folder: `/media/movies`
   - Enable **"Use Hardlinks instead of Copy"**
2. **Settings → Download Clients → Add → qBittorrent**
   - Host: `qbittorrent` (container name)
   - Port: `8080`
   - Username/Password: from qBittorrent Web UI
   - Category: `radarr`
3. **Movies → Add New** → search and add movies

### Sonarr (TV Show Manager)

**URL:** http://localhost:8989

1. **Settings → Media Management**
   - Root Folder: `/media/tv`
   - Enable **"Use Hardlinks instead of Copy"**
2. **Settings → Download Clients → Add → qBittorrent**
   - Host: `qbittorrent`
   - Port: `8080`
   - Category: `tv-sonarr`
3. **Series → Add New** → search and add series

### Jellyfin (Media Player)

**URL:** http://localhost:8096

1. Run the setup wizard
2. Add **Movies** library → folder `/media/movies`
3. Add **TV Shows** library → folder `/media/tv`
4. If content doesn't appear: **Dashboard → Libraries → Scan Library**

### Portainer (Docker Manager)

**URL:** http://localhost:9000

1. Create admin account on first visit
2. Select **"Get started"** → **"Live connect"** to local Docker
3. Use to view logs, restart containers, open console — all from browser

### Homepage (Dashboard)

**URL:** http://localhost:3000

- Displays quick links, live widgets (download queue, movie counts, system stats)
- Config is in `homepage/services.yaml` (uses `${VAR}` from `.env`)
- If widgets show errors: check that `.env` has correct API keys, then `docker restart homepage`

---

## How It Works

```
You add a movie in Radarr
        ↓
Prowlarr searches indexers
        ↓
Radarr sends torrent to qBittorrent
        ↓
qBittorrent downloads to /media/downloads/
        ↓
Radarr detects 100% complete
        ↓
Radarr hardlinks file to /media/movies/
        ↓
Jellyfin scans library → movie appears
        ↓
You watch it
```

**Hardlinks** mean the file exists in two folders but uses disk space only once. The original stays in `downloads/` for seeding; the library copy in `movies/` or `tv/` is just a pointer to the same data.

---

## Access from Other Devices

Find your server IP:
- **Windows:** `ipconfig` → IPv4 Address
- **Linux:** `hostname -I`

| Service | On server | From phone/TV/tablet |
|---------|-----------|---------------------|
| Homepage | http://localhost:3000 | http://YOUR_IP:3000 |
| Jellyfin | http://localhost:8096 | http://YOUR_IP:8096 |
| Radarr | http://localhost:7878 | http://YOUR_IP:7878 |
| Sonarr | http://localhost:8989 | http://YOUR_IP:8989 |
| qBittorrent | http://localhost:8080 | http://YOUR_IP:8080 |
| Portainer | http://localhost:9000 | http://YOUR_IP:9000 |

**Jellyfin apps:** Download the Jellyfin app on your phone/TV, enter `http://YOUR_IP:8096` as the server address.

---

## Windows Firewall

If other devices can't connect:

1. **Windows Defender Firewall → Advanced Settings → Inbound Rules → New Rule**
2. Select **Port** → TCP
3. Ports: `3000,8096,7878,8989,9696,8080,9000`
4. Allow for **Private** network profile
5. Name: "Media Server"

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Host validation failed" (Homepage) | Check `HOMEPAGE_ALLOWED_HOSTS` in `.env` matches the URL you typed |
| Cannot connect to qBittorrent from Radarr | Ensure qBittorrent Web UI is enabled; use host `qbittorrent` (not `localhost`) |
| No posters in Sonarr/Radarr | Wait 2–3 min for metadata fetch; force refresh: **System → Tasks → Update All** |
| Jellyfin doesn't see files | Check library path is `/media/movies` or `/media/tv`; force **Scan Library** |
| qBittorrent won't start after restart | Config corruption: `docker compose down`, delete `data/qbittorrent/*`, `docker compose up -d` |
| Port already in use | Change left-side port in `docker-compose.yml` (e.g., `8082:8080`) |

---

## Updates

```bash
docker compose pull
docker compose up -d
```

All configs and media are preserved in `./data/` and `./library/`.

---

## Security

- **Never commit `.env` to Git.** It contains API keys and network details.
- `data/` and `library/` are gitignored — they contain runtime state and media.
- For remote access outside your home, use a reverse proxy (Nginx Proxy Manager, Traefik) with HTTPS — do not port-forward these apps directly.
