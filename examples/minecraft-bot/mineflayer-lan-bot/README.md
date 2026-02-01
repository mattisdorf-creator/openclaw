Mineflayer LAN fallback — combat & autocraft

Quick start (after opening Singleplayer world -> Open to LAN):

1) Install deps:
   pnpm install --filter ./examples/minecraft-bot/mineflayer-lan-bot

2) Combat micro (basic):
   pnpm --filter ./examples/minecraft-bot/mineflayer-lan-bot run combat

3) Autocraft (example: bucket):
   pnpm --filter ./examples/minecraft-bot/mineflayer-lan-bot run autocraft -- bucket

   Note: the Fabric client mod also registers a client command `/openclaw craft <recipe>` (example: `/openclaw craft bucket`).
   The client mod will forward that request as `openclaw_request craft <recipe>` so the Mineflayer fallback (or the watcher) can perform the craft automatically when available.

4) Seed harness test:
   pnpm --filter ./examples/minecraft-bot/mineflayer-lan-bot run test-seed

Notes
- These bots are fallbacks for when client mods/autocraft aren't available.
- They are not a replacement for Baritone's pathing but useful for crafting + combat micro in LAN testing.
- To integrate with watcher: set MINEFLAYER_FALLBACK=1 and the watcher will suggest the fallback (manual start required).