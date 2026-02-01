#!/usr/bin/env bash
set -euo pipefail

# one_click_start.sh
# "Open Minecraft -> automation starts" helper.
# - generates a random seed
# - starts the autostart watcher (if not already running)
# - focuses Minecraft, creates a NEW singleplayer world with that seed via xdotool
# - after the world loads it posts the seed to chat (for reproducibility) and
#   sends a fallback craft + speedrun trigger so Mineflayer/Baritone pick it up.
#
# Requirements: xdotool, rg (ripgrep) or grep, Minecraft (Fabric profile), autostart-watcher.sh
# Usage: ./one_click_start.sh [--no-watch] [--no-ui] [--seed 12345]

HERE="$(cd "$(dirname "$0")" && pwd)/.."
WATCHER="$HERE/autostart-watcher.sh"
MC_LOG="$HOME/.minecraft/logs/latest.log"
XDO_TOOL=$(command -v xdotool || true)
RG=$(command -v rg || command -v grep)

print_usage(){
  cat <<EOF
one_click_start.sh — create new random world and start OpenClaw automation

Usage: $0 [--seed <seed>] [--no-watch] [--no-ui]

Options:
  --seed <n>    Use a specific seed instead of a random one
  --no-watch    Don't start the autostart watcher (you already have it)
  --no-ui       Only prepare files and send chat triggers (assumes world already open)

Prereqs: xdotool + an X11/Wayland XWayland session, Fabric profile selected in the launcher.
EOF
}

SEED_ARG=""
START_WATCH=1
ONLY_UI=0
while [[ ${1:-} != "" ]]; do
  case "$1" in
    --seed) SEED_ARG="$2"; shift 2;;
    --no-watch) START_WATCH=0; shift;;
    --no-ui) ONLY_UI=1; shift;;
    -h|--help) print_usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; print_usage; exit 2 ;;
  esac
done

if [ -z "$SEED_ARG" ]; then
  # 64-bit random seed (signed range is fine for Minecraft)
  SEED=$(od -An -N8 -tu8 < /dev/urandom | tr -d ' ')
else
  SEED="$SEED_ARG"
fi

echo "OpenClaw one-click start — seed=$SEED"

# start watcher if requested
if [ $START_WATCH -eq 1 ]; then
  if pgrep -f autostart-watcher.sh >/dev/null 2>&1; then
    echo "autostart-watcher already running"
  else
    echo "Starting autostart-watcher in background (~tail -f latest.log)"
    nohup "$WATCHER" "$MC_LOG" >/tmp/openclaw-watcher.log 2>&1 &
    sleep 0.7
  fi
fi

if [ $ONLY_UI -eq 1 ]; then
  echo "Skipping UI automation (assume Minecraft already open). Sending seed + triggers to chat..."
  if [ -z "$XDO_TOOL" ]; then
    echo "xdotool required to send chat messages" >&2
    exit 3
  fi
  WIN_ID=$($XDO_TOOL search --onlyvisible --name Minecraft | head -n1 || true)
  if [ -z "$WIN_ID" ]; then echo "Minecraft window not found" >&2; exit 4; fi
  $XDO_TOOL windowactivate --sync $WIN_ID
  sleep 0.5
  $XDO_TOOL key --window $WIN_ID t
  sleep 0.12
  $XDO_TOOL type --window $WIN_ID --delay 8 -- "openclaw:seed $SEED"
  $XDO_TOOL key --window $WIN_ID Return
  sleep 0.5
  # request an initial craft (bucket) so Mineflayer fallback can prepare
  $XDO_TOOL key --window $WIN_ID t
  sleep 0.12
  $XDO_TOOL type --window $WIN_ID --delay 8 -- "openclaw_request craft bucket"
  $XDO_TOOL key --window $WIN_ID Return
  sleep 0.5
  # also request speedrun script (Baritone will ignore if missing)
  $XDO_TOOL key --window $WIN_ID t
  sleep 0.12
  $XDO_TOOL type --window $WIN_ID --delay 8 -- "#script speedrun_v2"
  $XDO_TOOL key --window $WIN_ID Return
  echo "Sent seed + fallback triggers to in-game chat"
  exit 0
fi

# From here: attempt to *create a new world* via UI automation
if [ -z "$XDO_TOOL" ]; then
  echo "xdotool not found — please install it (sudo apt install xdotool) and re-run" >&2
  exit 5
fi

WIN_ID=$($XDO_TOOL search --onlyvisible --name Minecraft | head -n1 || true)
if [ -z "$WIN_ID" ]; then
  echo "Minecraft window not found. Start the Minecraft launcher, select your Fabric profile and open the game, then re-run this script." >&2
  exit 6
fi

echo "Found Minecraft window id=$WIN_ID — creating new singleplayer world (this will click UI controls)."
$XDO_TOOL windowactivate --sync $WIN_ID
sleep 0.6

# sequence: Singleplayer -> Create New World -> More Options -> Seed -> type seed -> Create New World
# Note: relies on English UI layout; if you run a localized client, open the UI manually once and then use --no-ui mode.
$XDO_TOOL key --window $WIN_ID --clearmodifiers Return # ensure window focused
sleep 0.5
# press 'Singleplayer' (usually the first button) — fall back to mouseclick in the middle
$XDO_TOOL key --window $WIN_ID s
sleep 0.6
# try to click 'Create New World' by relative coordinates — best-effort
$XDO_TOOL key --window $WIN_ID c
sleep 0.8
# open More World Options (press Tab a few times then Enter — heuristic)
$XDO_TOOL key --window $WIN_ID Tab Tab Tab Tab Return
sleep 0.6
# focus seed field and type
$XDO_TOOL type --window $WIN_ID --delay 8 -- "$SEED"
sleep 0.4
# press 'Done' then 'Create New World'
$XDO_TOOL key --window $WIN_ID Return
sleep 0.6
$XDO_TOOL key --window $WIN_ID Return

# wait for integrated server start (tail logs)
echo "Waiting for world to finish loading (logs: $MC_LOG)"
secs=0
while [ $secs -lt 120 ]; do
  if $RG -i --no-line-number --passthru 'Started integrated server|Starting integrated minecraft server|Loading world' "$MC_LOG" >/dev/null 2>&1; then
    echo "World loading detected in log"
    break
  fi
  sleep 1
  secs=$((secs+1))
done

if [ $secs -ge 120 ]; then
  echo "Timeout waiting for world start; the UI automation may have failed. Try running with --no-ui and create the world manually." >&2
  exit 7
fi

sleep 4
# focus and post the seed + fallback triggers
$XDO_TOOL windowactivate --sync $WIN_ID
sleep 0.6
$XDO_TOOL key --window $WIN_ID t
sleep 0.12
$XDO_TOOL type --window $WIN_ID --delay 8 -- "openclaw:seed $SEED"
$XDO_TOOL key --window $WIN_ID Return
sleep 0.5

# request an initial craft (bucket) so Mineflayer fallback can prepare
$XDO_TOOL key --window $WIN_ID t
sleep 0.12
$XDO_TOOL type --window $WIN_ID --delay 8 -- "openclaw_request craft bucket"
$XDO_TOOL key --window $WIN_ID Return
sleep 0.5

# finally also send the Baritone script trigger (watcher will do it too)
$XDO_TOOL key --window $WIN_ID t
sleep 0.12
$XDO_TOOL type --window $WIN_ID --delay 8 -- "#script speedrun_v2"
$XDO_TOOL key --window $WIN_ID Return

echo "One‑click flow complete — seed posted to chat: $SEED"
echo "If Baritone is installed the speedrun should begin; if not, Mineflayer fallback will attempt autocraft and assist."

exit 0
