const mineflayer = require('mineflayer')
const { spawn } = require('child_process')

// LAN bot: connects to localhost:25565 (singleplayer opened to LAN)
// Enhanced: listens for openclaw requests in chat and forwards to autocraft/combat handlers.
// Usage: open your world -> Open to LAN -> run this script in the same machine

const bot = mineflayer.createBot({
  host: process.env.HOST || 'localhost',
  port: parseInt(process.env.PORT || '25565', 10),
  username: process.env.USERNAME || ('AutoPlayBot_' + Math.floor(Math.random()*10000))
})

bot.once('spawn', async () => {
  console.log('Bot spawned — enhanced LAN PoC')
  bot.chat('AutoPlayBot online — listening for openclaw requests')
})

// listen to chat for requests from the client/modscript
// expected syntax: openclaw_request craft <recipe>
bot.on('chat', (username, message) => {
  try {
    if (!message) return
    const m = message.toString().trim()
    if (/^openclaw_request craft (\S+)/i.test(m)) {
      const recipe = m.split(/\s+/)[2]
      bot.chat(`Received craft request: ${recipe} — attempting via autocraft fallback`)
      // spawn autocraft helper as a separate process (simpler than wiring functions)
      const p = spawn(process.execPath, [require.resolve('./autocraft.js'), recipe], { cwd: __dirname })
      p.stdout.pipe(process.stdout)
      p.stderr.pipe(process.stderr)
      p.on('exit', (code) => bot.chat(`Autocraft helper exited (code=${code})`))
    }

    if (/^openclaw_request start_speedrun/i.test(m)) {
      bot.chat('Received request: start_speedrun — attempting to trigger speedrun script locally')
      // If Baritone is present on the client, the watcher/mod should handle script injection.
      // This fallback notifies the user and can be extended to perform other actions.
    }
  } catch (err) {
    console.error('chat handler error', err)
  }
})

bot.on('kicked', console.log)
bot.on('error', console.log)

module.exports = bot
