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

Troubleshooting
- If watcher reports "xdotool not found": install it (`sudo apt install xdotool`) or run the chat command manually.  
- If Baritone is not installed: download a Fabric build from https://github.com/cabaletta/baritone/releases and place it into `~/.minecraft/mods/` then restart Minecraft.

If you want, I can create a desktop launcher so the watcher starts automatically when you login — say "Launcher bitte".