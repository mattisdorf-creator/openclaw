// Simple verification harness for a LAN singleplayer world.
// Run after opening your world to LAN (default port 25565).
// Usage: node test_seed.js

const mineflayer = require('mineflayer')

const bot = mineflayer.createBot({
  host: 'localhost',
  port: 25565,
  username: 'TestHarness_' + Math.floor(Math.random()*10000)
})

function quit(code = 0) {
  setTimeout(() => process.exit(code), 600)
}

bot.once('spawn', async () => {
  console.log('Harness: connected — running checks')
  try {
    // Check: find a nearby log block
    const tree = bot.findBlock({ matching: b => b.name && b.name.includes('log'), maxDistance: 64 })
    console.log('Found log?', !!tree)

    // Check: can see stone within 64 blocks
    const stone = bot.findBlock({ matching: b => b.name && b.name === 'stone', maxDistance: 64 })
    console.log('Found stone?', !!stone)

    // Simple simulated action: if a log is found, attempt to dig it (permission dependent)
    if (tree) {
      await bot.dig(tree)
      console.log('Dig action succeeded (or attempted)')
    }

    console.log('Harness: checks complete — OK')
    quit(0)
  } catch (err) {
    console.error('Harness error', err)
    quit(2)
  }
})

bot.on('error', (err) => console.error('bot error', err))
bot.on('end', () => console.log('bot disconnected'))
