# Minecraft Auto‑Play (Fabric + Baritone) — PoC

Kurzversion (wenn du schnell starten willst):
1. Minecraft‑Version: **latest** (Standard; das Install‑Script löst die neueste Release‑Version automatisch auf — du kannst `--mc-version <version>` angeben)
2. Installiere Fabric Loader + Fabric API für deine MC‑Version
3. Installiere **Baritone (fabric build)** in `~/.minecraft/mods/`
4. Baue diese Mod: `cd examples/minecraft-bot/fabric-autoplay && ./gradlew -PmcVersion=<version> build`
5. Kopiere `build/libs/*-dev.jar` nach `~/.minecraft/mods/`
6. Minecraft starten → single‑player Welt öffnen → die Mod startet automatisch und führt das mitgelieferten Baritone‑Script `autoplay` aus.

Ziel dieser PoC‑Mod:
- Beim Laden einer Single‑player‑Welt automatisch ein Baritone‑Script starten (wenn Baritone installiert ist).
- Fallback: sichtbare Hinweis‑Nachricht im Spiel, falls Baritone fehlt.

Wichtiges zu Sicherheit & Fairplay ⚠️
- Verwende die Automation nur auf eigenen Welten / mit Erlaubnis auf Servern. Anti‑Cheat/Serverregeln können zu Bans führen.

Was du anpassen kannst
- `baritone-scripts/autoplay.bt` — Hauptskript (einfach zu editieren)
- `fabric-autoplay/src/main/java/.../AutoPlayMod.java` — Verhalten (Autostart‑Delay, Benachrichtigungen)

Fehlerbehebung (kurz)
- Wenn nichts passiert: prüfe, ob `baritone` in `mods/` liegt und die MC‑Version stimmt.
- Wenn Baritone installiert ist, aber Skript nicht ausgeführt wird: öffne Chat und probiere `#script autoplay` manuell (Baritone‑Kommando).

Wenn du willst, baue ich die Mod jetzt hier im Container und lege das JAR unter `examples/minecraft-bot/dist/` ab (braucht Java/Gradle). Soll ich das tun?