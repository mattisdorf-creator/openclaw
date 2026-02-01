const mineflayer = require('mineflayer')

// Simple LAN bot: connects to localhost:25565 (singleplayer opened to LAN)
// Usage: open your world -> Open to LAN -> run this script in the same machine

const bot = mineflayer.createBot({
  host: 'localhost',
  port: 25565,
  username: 'AutoPlayBot_' + Math.floor(Math.random()*10000)
})

bot.once('spawn', async () => {
  console.log('Bot spawned — starting simple autoplay PoC')
  bot.chat('AutoPlayBot online — starting resource gathering')
  try {
    // find nearest log and dig it (very simple PoC)
    const tree = bot.findBlock({ matching: b => b.name && b.name.includes('log'), maxDistance: 64 })
    if (tree) {
      await bot.dig(tree)
      bot.chat('collected wood')
    } else {
      bot.chat('no log found nearby — wandering')
      bot.setControlState('forward', true)
      setTimeout(() => bot.setControlState('forward', false), 3000)
    }
  } catch (err) {
    console.error('action error', err)
  }
})

bot.on('kicked', console.log)
bot.on('error', console.log)
