# Media Server Configs

## Files
- `.env` — environment variables (IP, timezone, user IDs)
- `docker-compose.yml` — full stack with labels for Homepage auto-discovery
- `homepage/settings.yaml` — Homepage theme & layout
- `homepage/services.yaml` — Homepage manual service cards + widgets
- `homepage/widgets.yaml` — System stats + search bar
- `homepage/docker.yaml` — Docker socket config for auto-discovery

## Setup
1. Edit `.env` — change `SERVER_IP` to your actual LAN IP
2. Edit `homepage/services.yaml` — replace placeholder API keys and passwords
3. Copy all files to your `media/` folder so the structure looks like:
   ```
   media/
   ├── .env
   ├── docker-compose.yml
   ├── data/
   └── homepage/
       ├── settings.yaml
       ├── services.yaml
       ├── widgets.yaml
       └── docker.yaml
   ```
4. Run: `docker compose up -d`
5. Access:
   - Homepage: http://YOUR_IP:3000
   - Portainer: http://YOUR_IP:9000

## API Keys — where to find them
| Service | Path |
|---------|------|
| Radarr | Settings → General → API Key |
| Sonarr | Settings → General → API Key |
| Jellyfin | Dashboard → Advanced → API Keys → + |
| qBittorrent | Tools → Options → Web UI |
| Portainer | My Account → Access tokens |
