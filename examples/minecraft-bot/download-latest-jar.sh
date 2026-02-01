#!/usr/bin/env bash
set -euo pipefail

# Download the latest workflow-built JAR for the Fabric AutoPlay mod from GitHub Actions.
# Usage: ./download-latest-jar.sh <owner> <repo> [dest-dir]
# Example: ./download-latest-jar.sh openclaw openclaw ~/Downloads

OWNER=${1:-openclaw}
REPO=${2:-openclaw}
DEST=${3:-.}

if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  echo "Bitte installiere 'curl' und 'jq' (z. B. apt install curl jq)" >&2
  exit 1
fi

API="https://api.github.com/repos/${OWNER}/${REPO}/actions/workflows/build-minecraft-autoplay.yml/runs?per_page=50"

echo "Abfrage der letzten erfolgreichen Workflow‑Runs..."

RUN_ID=$(curl -s "$API" | jq -r '.workflow_runs[] | select(.conclusion=="success") | .id' | head -n1)
if [ -z "$RUN_ID" ]; then
  echo "Kein erfolgreicher Build‑Run gefunden. Öffne die Actions‑Seite: https://github.com/${OWNER}/${REPO}/actions/workflows/build-minecraft-autoplay.yml" >&2
  exit 1
fi

ARTIFACTS_API="https://api.github.com/repos/${OWNER}/${REPO}/actions/runs/${RUN_ID}/artifacts"
ART_ID=$(curl -s "$ARTIFACTS_API" | jq -r '.artifacts[] | select(.name=="openclaw-autoplay-jar") | .id')
if [ -z "$ART_ID" ]; then
  echo "Kein passendes Artefakt im Run #${RUN_ID} gefunden." >&2
  exit 1
fi

ZIP_URL="https://api.github.com/repos/${OWNER}/${REPO}/actions/artifacts/${ART_ID}/zip"

mkdir -p "$DEST"
TMPZIP=$(mktemp /tmp/artifact.XXXXXX.zip)

# If repo is private you will need GITHUB_TOKEN env var with repo scope.
if [ -n "${GITHUB_TOKEN:-}" ]; then
  curl -sSL -H "Authorization: token ${GITHUB_TOKEN}" -o "$TMPZIP" "$ZIP_URL"
else
  curl -sSL -o "$TMPZIP" "$ZIP_URL"
fi

unzip -o "$TMPZIP" -d "$DEST"
rm -f "$TMPZIP"

echo "JAR entpackt nach: $DEST (suche nach openclaw-autoplay-*.jar)"
