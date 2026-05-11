#!/bin/bash

CONFIG_DIR="/config/qBittorrent/config"
CONFIG_FILE="$CONFIG_DIR/qBittorrent.conf"

mkdir -p "$CONFIG_DIR"

if [ -f "$CONFIG_FILE" ]; then
    # Patch existing config if WebUI got disabled
    if grep -q 'WebUI\\Enabled=false' "$CONFIG_FILE"; then
        sed -i 's/WebUI\\Enabled=false/WebUI\\Enabled=true/g' "$CONFIG_FILE"
        echo "[custom-init] Re-enabled qBittorrent WebUI"
    fi
    
    # Ensure port stays 8080
    sed -i 's/^WebUI\\Port=.*/WebUI\\Port=8080/g' "$CONFIG_FILE"
    
    # Ensure localhost bypass is off (so Radarr/Sonarr can auth properly)
    sed -i 's/WebUI\\LocalHostAuth=true/WebUI\\LocalHostAuth=false/g' "$CONFIG_FILE"
else
    # First boot: create a clean config with WebUI pre-enabled
    cat > "$CONFIG_FILE" <<'EOF'
[LegalNotice]
Accepted=true

[Preferences]
WebUI\Enabled=true
WebUI\Port=8080
WebUI\LocalHostAuth=false
WebUI\Username=admin
Downloads\SavePath=/media/downloads
Downloads\TempPathEnabled=false
EOF
    echo "[custom-init] Created fresh qBittorrent config with WebUI enabled"
fi
