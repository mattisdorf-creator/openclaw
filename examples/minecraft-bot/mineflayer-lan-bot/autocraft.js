// autocraft.js — simple Mineflayer autocraft helper for speedrun harness
// - Crafts basic items when ingredients are present (crafting table required for some recipes)
// - Usage: node autocraft.js <recipeId>  (example: 'stone_pickaxe')

const mineflayer = require('mineflayer')
const recipes = require('prismarine-recipes') // lightweight mapping (not required but helpful)

const bot = mineflayer.createBot({
  host: process.env.HOST || 'localhost',
  port: parseInt(process.env.PORT || '25565', 10),
  username: process.env.USERNAME || ('AutoCraft_' + Math.floor(Math.random() * 10000))
})

bot.once('spawn', async () => {
  console.log('Autocraft bot spawned — ready')
  const recipeName = process.argv[2] || 'stone_pickaxe'
  try {
    await craftRecipe(recipeName)
    console.log('Crafting attempt finished for', recipeName)
    process.exit(0)
  } catch (err) {
    console.error('craft failed', err)
    process.exit(2)
  }
})

async function craftRecipe (name) {
  // Minimal known recipes map (expand as needed)
  const known = {
    stone_pickaxe: { result: 'stone_pickaxe', ingredients: { cobblestone: 3, stick: 2 } },
    bucket: { result: 'bucket', ingredients: { iron_ingot: 3 } },
    furnace: { result: 'furnace', ingredients: { cobblestone: 8 } }
  }
  const r = known[name]
  if (!r) throw new Error('unknown recipe: ' + name)

  // check inventory
  const inv = bot.inventory.items().reduce((acc, it) => { acc[it.name] = (acc[it.name] || 0) + it.count; return acc }, {})
  for (const k of Object.keys(r.ingredients)) {
    if ((inv[k] || 0) < r.ingredients[k]) throw new Error('missing ingredient: ' + k)
  }

  // try crafting on player crafting grid (if table required, assume player placed/has one)
  // use bot.craft if recipe exists in mc data
  const mcData = require('minecraft-data')(bot.version)
  const recipe = bot.recipesFor(mcData.itemsByName[r.result].id, null, 1)[0]
  if (!recipe) throw new Error('no matching recipe available in this environment')
  await bot.craft(recipe, 1, null)
}

bot.on('error', console.error)
bot.on('end', () => console.log('bot disconnected'))
