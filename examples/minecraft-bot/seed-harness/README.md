Seed‑Harness — deterministic testing notes

Purpose
- Provide a repeatable workflow to evaluate and iterate on speedrun scripts against a fixed world seed.

What you do
1) Create a new singleplayer world with a chosen seed (example: `-1234567890123456789`).
2) Open to LAN (default port 25565) so test harness can connect.
3) Run the Mineflayer verification script to assert early milestones (wood gathered, stone pick crafted, iron found).

Quick checklist (manual)
- Use a world seed dedicated to iteration (don't use survival base seeds).
- Test each script incrementally: `autoplay` → `speedrun_v2` → `portal_builder` → `pearl_fallback`.

Automation (manual steps are required):
- Open the world to LAN.
- Run: `node mineflayer-lan-bot/test_seed.js` (see script) — it will attempt basic checks and report pass/fail.

Next improvements
- Automate world creation + server startup (future): use a headless server with prepared world saves.
- Integrate deterministic unit tests that run the Mineflayer harness against prepared saves.
