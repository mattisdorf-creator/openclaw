#!/usr/bin/env bash
set -euo pipefail

# Minimal helper to build the PoC mod and (optionally) download Baritone.
# Usage: ./install.sh [--mc-version 1.20.4] [--mods-dir ~/.minecraft/mods]

MC_VERSION="latest"
MODS_DIR="$HOME/.minecraft/mods"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mc-version) MC_VERSION="$2"; shift 2;;
    --mods-dir) MODS_DIR="$2"; shift 2;;
    --help) sed -n '1,200p' "$0"; exit 0;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

# resolve "latest" to the latest Mojang release (best-effort)
if [ "$MC_VERSION" = "latest" ]; then
  echo "Auflösung der neuesten Minecraft‑Release‑Version..."
  if command -v python3 >/dev/null 2>&1; then
    MC_VERSION=$(python3 -c "import json,urllib.request as u; print(json.load(u.urlopen('https://launchermeta.mojang.com/mc/game/version_manifest.json'))['latest']['release'])" 2>/dev/null || true)
  fi
  MC_VERSION=${MC_VERSION:-1.20.4}
  echo "Verwende Minecraft Version: $MC_VERSION"
fi

echo "Building OpenClaw AutoPlay mod (MC $MC_VERSION)..."
cd "$PROJECT_DIR/fabric-autoplay"

# prefer ./gradlew, fall back to system 'gradle' if available
GRADLE_CMD="./gradlew"
if [ ! -x ./gradlew ]; then
  if command -v gradle >/dev/null 2>&1; then
    GRADLE_CMD="gradle"
    echo "Kein ./gradlew gefunden — benutze system 'gradle' (falls installiert)."
  else
    echo "Kein ./gradlew und kein system 'gradle' gefunden — bitte Gradle installieren oder die Wrapper-Dateien generieren." >&2
  fi
fi

# pass mcVersion to Gradle; if the build for the requested MC version fails, fall back to 1.20.4 and inform the user
if $GRADLE_CMD clean build -PmcVersion="$MC_VERSION" --no-daemon; then
  :
else
  echo "Build für $MC_VERSION fehlgeschlagen — versuche Fallback auf 1.20.4" >&2
  if $GRADLE_CMD clean build -PmcVersion=1.20.4 --no-daemon; then
    echo "Fallback Build (1.20.4) erfolgreich — das JAR wird installiert, kann aber mit neuerer MC-Version inkompatibel sein." >&2
  else
    echo "Beide Builds sind fehlgeschlagen: installiere ein passendes JDK (17+), prüfe Internetzugang und versuche erneut." >&2
    exit 1
  fi
fi

mkdir -p "$MODS_DIR"
cp build/libs/openclaw-autoplay-*.jar "$MODS_DIR/"

echo "Mod jar copied to $MODS_DIR"

# Try to help download Baritone (best-effort). Will not overwrite existing file.
BARITONE_GUESS="baritone-fabric-${MC_VERSION}.jar"
if ls "$MODS_DIR" | rg -i baritone >/dev/null 2>&1; then
  echo "Baritone already present in $MODS_DIR — skipping download."
else
  echo
  echo "Attempting to download Baritone (best-effort). If this fails, follow the README instructions." 
  BARITONE_URL="https://github.com/cabaletta/baritone/releases/latest/download/${BARITONE_GUESS}"
  echo "Trying: $BARITONE_URL"
  if curl -fL --progress-bar -o "$MODS_DIR/$BARITONE_GUESS" "$BARITONE_URL"; then
    echo "Downloaded Baritone to $MODS_DIR/$BARITONE_GUESS"
  else
    echo "Automated Baritone download failed — please download a Fabric build for ${MC_VERSION} from:" >&2
    echo "  https://github.com/cabaletta/baritone/releases" >&2
  fi
fi

echo
echo "Fertig ✅ — starte Minecraft (Profile: Fabric ${MC_VERSION}) und öffne eine Singleplayer‑Welt."
echo "Die Mod führt beim Weltstart automatisch das Baritone‑Script 'autoplay' aus (sofern Baritone installiert ist)."
