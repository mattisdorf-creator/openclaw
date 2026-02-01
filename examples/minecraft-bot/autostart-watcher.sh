#!/usr/bin/env bash
set -euo pipefail

# autostart-watcher.sh
# Watches Minecraft's latest.log for an integrated-server world start and
# then focuses the Minecraft window and types the Baritone chat command
# '#script autoplay'. Designed as a no-mod fallback to trigger Baritone
# when Fabric + Baritone are installed in ~/.minecraft/mods/.

# Usage: ./autostart-watcher.sh [--mc-log ~/.minecraft/logs/latest.log] [&]

MC_LOG_DEFAULT="$HOME/.minecraft/logs/latest.log"
MC_LOG="${1:-$MC_LOG_DEFAULT}"
# choose command: speedrun if SPEEDRUN flag present, otherwise default to autoplay
if [ -n "${SPEEDRUN:-}" ] || [ -f "$(pwd)/SPEEDRUN" ] || [ -f "$HOME/openclaw-autoplay/SPEEDRUN" ]; then
  CHAT_COMMAND="#script speedrun"
else
  CHAT_COMMAND="#script autoplay"
fi
POLL_INTERVAL=1
TIMEOUT=120

# Helpers
command_exists() { command -v "$1" >/dev/null 2>&1; }

if ! command_exists xdotool; then
  echo "WARN: 'xdotool' not found. Install it (e.g. 'sudo apt install xdotool') to enable automatic chat injection." >&2
  echo "You can still run the command manually in Minecraft chat: $CHAT_COMMAND" >&2
fi

if [ ! -f "$MC_LOG" ]; then
  echo "Minecraft log not found at $MC_LOG — waiting for file to appear (start Minecraft now)..."
  secs=0
  while [ ! -f "$MC_LOG" ] && [ $secs -lt $TIMEOUT ]; do
    sleep $POLL_INTERVAL
    secs=$((secs + POLL_INTERVAL))
  done
  if [ ! -f "$MC_LOG" ]; then
    echo "Timeout: Minecraft log did not appear. Ensure Minecraft has been started at least once." >&2
    exit 2
  fi
fi

echo "Watching Minecraft log: $MC_LOG"

# Wait for integrated server start message (covers singleplayer world load)
# Accept several possible log phrases depending on MC version / loader
START_RE='Starting integrated minecraft server|Started integrated server|Loading world'
secs=0
while [ $secs -lt $TIMEOUT ]; do
  if rg -i --no-line-number --passthru "$START_RE" -n "$MC_LOG" >/dev/null 2>&1; then
    echo "Detected world start in log (tailing)..."
    break
  fi
  sleep $POLL_INTERVAL
  secs=$((secs + POLL_INTERVAL))
done

if [ $secs -ge $TIMEOUT ]; then
  echo "Timeout waiting for world start in log." >&2
  exit 3
fi

# Give the client a few seconds to finish loading UI
sleep 3

# If Baritone is not present, try to download a Fabric build (best-effort)
if [ -d "$HOME/.minecraft/mods" ]; then
  if ! ls "$HOME/.minecraft/mods" | rg -i 'baritone' >/dev/null 2>&1; then
    echo "Baritone not detected in ~/.minecraft/mods — attempting best-effort download..."
    if command_exists curl && command_exists jq; then
      ASSET=$(curl -sS https://api.github.com/repos/cabaletta/baritone/releases | jq -r '.[] .assets[] | select(.name|test("fabric";"i")) | .browser_download_url' | head -n1 || true)
      if [ -n "$ASSET" ]; then
        echo "Downloading Baritone from: $ASSET"
        curl -sSL -o "$HOME/.minecraft/mods/$(basename "$ASSET")" "$ASSET" && echo "Baritone downloaded." || echo "Automated download failed; please download manually from https://github.com/cabaletta/baritone/releases" >&2
      else
        echo "No fabric asset found on releases page — please download Baritone manually: https://github.com/cabaletta/baritone/releases" >&2
      fi
    else
      echo "curl/jq not available — cannot auto-download Baritone. Install or add Baritone jar to ~/.minecraft/mods manually." >&2
    fi
  else
    echo "Baritone detected in mods/ — good." 
  fi
else
  echo "mods/ folder not found; creating: ~/.minecraft/mods" && mkdir -p "$HOME/.minecraft/mods"
fi

# Focus Minecraft window and send chat command (requires X11 + xdotool)
if command_exists xdotool; then
  # find the Minecraft window (try several common names)
  WIN_ID=$(xdotool search --onlyvisible --name "Minecraft" | head -n1 || true)
  if [ -z "$WIN_ID" ]; then
    # try matching by class
    WIN_ID=$(xdotool search --onlyvisible --class minecraft | head -n1 || true)
  fi
  if [ -n "$WIN_ID" ]; then
    echo "Focusing Minecraft window id=$WIN_ID and sending chat command..."
    xdotool windowactivate --sync $WIN_ID
    sleep 0.5
    xdotool key --window $WIN_ID t
    sleep 0.15
    xdotool type --window $WIN_ID --delay 10 -- "$CHAT_COMMAND"
    xdotool key --window $WIN_ID Return
    echo "Chat command sent: $CHAT_COMMAND"
    echo "Wenn Baritone installiert ist, sollte es jetzt reagieren (sieh Chat auf Bestätigung)."
    exit 0
  else
    echo "Minecraft window not found (xdotool konnte kein Fenster matchen)." >&2
    echo "Bitte öffne Minecraft im Vordergrund und führe folgenden Befehl im Spiel-Chat aus: $CHAT_COMMAND" >&2
    exit 4
  fi
else
  echo "xdotool nicht verfügbar — öffne Minecraft und tippe manuell: $CHAT_COMMAND" >&2
  exit 5
fi