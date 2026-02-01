# Sprint: Autocraft + Combat micro (3 days)

Goals:
- Integrate client autocraft bridge + Mineflayer autocraft fallback
- Improve combat micro (strafing, healing, criticals, telemetry)
- Add CI smoke + seed harness tests

Deliverables:
1) Fabric client autocraft bridge (mod) + Baritone hooks
2) Mineflayer autocraft/combat improvements (done) + integration tests
3) CI smoke for integration + demo run artifacts

Milestones (daily):
- Day 1: Autocraft design + Mineflayer bridge + basic tests
- Day 2: Combat micro polish + integration tests
- Day 3: Client mod integration, CI, demo run + docs

Acceptance criteria:
- `#script speedrun_v2` can request a craft (bucket) and proceed without manual craft in the harness
- Combat micro survives basic hostile encounters in harness runs
- CI smoke validates harness on push

Testing / how to run locally:
- Open world to LAN -> run mineflayer harness (examples/minecraft-bot/mineflayer-lan-bot/test_seed.js)
- Enable SPEEDRUN_V2 and run watcher to validate integrated flow

