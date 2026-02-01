#!/usr/bin/env bash
set -euo pipefail

# install-launcher.sh
# Installs the OpenClaw AutoPlay watcher as:
# - ~/.local/bin/openclaw-autostart
# - ~/.local/share/applications/openclaw-autoplay.desktop
# - systemd user service: openclaw-autoplay.service (optional enable)

HERE="$(cd "$(dirname "$0")" && pwd)/.."
BIN="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
SERVICE_DIR="$HOME/.config/systemd/user"

mkdir -p "$BIN" "$DESKTOP_DIR" "$SERVICE_DIR"

echo "Installiere watcher binary to $BIN/openclaw-autostart"
cat > "$BIN/openclaw-autostart" <<'EOF'
#!/usr/bin/env bash
exec "$HOME/openclaw-autoplay/autostart-watcher.sh" "$@"
EOF
chmod +x "$BIN/openclaw-autostart"

echo "Installiere Desktop‑Launcher to $DESKTOP_DIR/openclaw-autoplay.desktop"
cat > "$DESKTOP_DIR/openclaw-autoplay.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=OpenClaw AutoPlay (watcher)
Comment=Startet den OpenClaw AutoPlay watcher (Autostart für Minecraft Automation)
Exec=$HOME/.local/bin/openclaw-autostart
Icon=applications-games
Terminal=false
Categories=Game;Utility;
StartupNotify=false
EOF

# systemd user unit
echo "Installiere systemd user unit to $SERVICE_DIR/openclaw-autoplay.service"
cat > "$SERVICE_DIR/openclaw-autoplay.service" <<'EOF'
[Unit]
Description=OpenClaw AutoPlay watcher (per-user)
After=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/openclaw-autostart
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

echo
echo "Installation abgeschlossen. Aktionen:
 - Sofort starten: systemctl --user start openclaw-autoplay.service
 - Beim Login aktivieren: systemctl --user enable --now openclaw-autoplay.service
 - Desktop‑Shortcut: finde 'OpenClaw AutoPlay (watcher)' in deinem Anwendungsmenü

Hinweis: Der watcher erwartet, dass du die ZIP an entpackst nach: ~/openclaw-autoplay
Wenn du die Dateien an einem anderen Ort hast, passe die Datei ~/.local/bin/openclaw-autostart an.
"