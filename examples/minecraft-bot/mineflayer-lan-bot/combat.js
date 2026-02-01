// combat.js — simple Mineflayer combat micro for LAN fallback
// Usage: open your singleplayer world -> Open to LAN (port 25565)
//        node combat.js

const mineflayer = require('mineflayer')
const { pathfinder, Movements } = require('mineflayer-pathfinder')
const pvp = require('mineflayer-pvp').plugin
const Vec3 = require('vec3')

const bot = mineflayer.createBot({
  host: process.env.HOST || 'localhost',
  port: parseInt(process.env.PORT || '25565', 10),
  username: process.env.USERNAME || ('AutoCombat_' + Math.floor(Math.random() * 10000))
})

bot.loadPlugin(pathfinder)
bot.loadPlugin(pvp)

bot.once('spawn', () => {
  console.log('Combat bot spawned — ready')
  bot.chat('AutoCombat online — switching to combat mode')
  startCombatLoop().catch(err => console.error('combat loop error', err))
})

async function equipBestWeapon () {
  const sword = bot.inventory.items().filter(i => /sword/.test(i.name)).sort((a, b) => b.attackBonus - a.attackBonus)[0]
  if (sword) await bot.equip(sword, 'hand')
}

async function startCombatLoop () {
  const mcData = require('minecraft-data')(bot.version)
  const defaultMove = new Movements(bot, mcData)
  bot.pathfinder.setMovements(defaultMove)

  bot.on('health', () => {
    if (bot.food === 20 && bot.health < 10) {
      // try to eat if low
      const food = bot.inventory.items().find(i => /(bread|cooked|steak|porkchop)/i.test(i.name))
      if (food) bot.equip(food, 'hand').catch(() => {})
    }
  })

  while (true) {
    try {
      // find nearest hostile mob (enderman excluded for safety unless distance large)
      const mob = bot.nearestEntity(entity => {
        if (!entity) return false
        const hostile = entity.type === 'mob' && (entity.mobType && /zombie|skeleton|creeper|spider|witch|blaze|ghast/i.test(entity.mobType))
        return hostile
      })

      if (!mob) {
        // wander/look for mobs
        await bot.waitForTicks(20)
        bot.setControlState('forward', true)
        await bot.waitForTicks(40)
        bot.setControlState('forward', false)
        await bot.waitForTicks(20)
        continue
      }

      console.log('Target acquired:', mob.name || mob.mobType || mob.type, 'at', mob.position)
      await equipBestWeapon()

      // approach and engage
      bot.pvp.attack(mob)

      // stay engaged until mob dies or we die
      let engaged = true
      while (engaged) {
        if (!mob || mob.isValid === false) break
        if (bot.health <= 4) {
          console.log('Health low — disengage')
          bot.pvp.stop(); engaged = false; break
        }
        await bot.waitForTicks(10)
      }

      await bot.waitForTicks(20)
    } catch (err) {
      console.error('combat loop caught', err)
      await new Promise(r => setTimeout(r, 2000))
    }
  }
}

bot.on('kicked', console.log)
bot.on('error', console.log)

module.exports = bot
