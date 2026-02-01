Quick fixes included in the "complete" ZIP

What this package does (auto-fix strategy):
- Autostart watcher (`autostart-watcher.sh`): watches Minecraft log, focuses the client window and injects `#script autoplay` into chat (requires xdotool + Baritone installed in ~/.minecraft/mods/). This makes the experience "open Minecraft → Automation starts".
- Baritone downloader (best-effort): watcher will attempt to download a Fabric Baritone jar if none is present.
- Mineflayer LAN fallback (`mineflayer-lan-bot/`): if client mods are not usable, run the Node LAN bot while you open the world to LAN.
- `run_autoplay_install.sh`: convenience installer to copy JARs and attempt Baritone download.

How to use (2 options)

A) Minimal — run watcher (recommended for Linux desktop)
1. Unzip the package somewhere:
   unzip openclaw-autoplay-complete-1.21.11.zip -d ~/openclaw-autoplay
2. Make watcher executable and run it in background:
   cd ~/openclaw-autoplay && chmod +x autostart-watcher.sh && ./autostart-watcher.sh &
3. Start Minecraft with the Fabric profile for 1.21.11 and open your Singleplayer world.
   - The watcher will detect the world load and send `#script autoplay` to the client chat.

B) LAN fallback (no mods needed)
1. Open your singleplayer world → Open to LAN (default port 25565).
2. In the package's `mineflayer-lan-bot/` folder run:
   pnpm install && node bot.js

Speedrun mode (AGGRESSIVE, use only on singleplayer)
- To enable basic speedrun: create an empty file named `SPEEDRUN` in the package folder (e.g. `~/openclaw-autoplay/SPEEDRUN`) or set env `SPEEDRUN=1` before launching `autostart-watcher.sh`.
- To enable the *deterministic* speedrun iteration (recommended for testing/iteration): create `SPEEDRUN_V2` or set `SPEEDRUN_V2=1` — the watcher will inject `#script speedrun_v2` and run the improved sequence.
- Behavior: `speedrun_v2` prioritizes deterministic resource acquisition, fast portal build heuristics and pearl fallbacks. Use a dedicated test seed when iterating.
- WARNING: speedrun modes are risky (fast, sometimes unsafe). Prefer a controlled singleplayer seed when testing.
Troubleshooting
- If watcher reports "xdotool not found": install it (`sudo apt install xdotool`) or run the chat command manually.  
- If Baritone is not installed: download a Fabric build from https://github.com/cabaletta/baritone/releases and place it into `~/.minecraft/mods/` then restart Minecraft.

If you want, I can create a desktop launcher so the watcher starts automatically when you login — say "Launcher bitte".

### Desktop launcher & autostart (one‑liner)

To install the launcher and enable autostart for your user, run (after you extracted the package to ~/openclaw-autoplay):

```bash
cd ~/openclaw-autoplay/launchers || true
chmod +x install-launcher.sh && ./install-launcher.sh
# start now and enable at login:
systemctl --user enable --now openclaw-autoplay.service
```

The launcher will appear as “OpenClaw AutoPlay (watcher)” in your application menu. To remove it:

```bash
systemctl --user disable --now openclaw-autoplay.service || true
rm -f ~/.local/bin/openclaw-autostart ~/.local/share/applications/openclaw-autoplay.desktop ~/.config/systemd/user/openclaw-autoplay.service
```