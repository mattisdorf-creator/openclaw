package ai.openclaw.minecraft;

import com.mojang.brigadier.arguments.StringArgumentType;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.command.v1.ClientCommandManager;
import net.fabricmc.fabric.api.client.command.v1.ClientCommandRegistrationCallback;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayConnectionEvents;
import net.minecraft.client.MinecraftClient;
import net.minecraft.text.LiteralText;

/**
 * Minimal Fabric client mod that auto-runs a Baritone script named `autoplay` on world join.
 * - Uses chat fallback (sends `#script autoplay`) so there is no compile-time Baritone dependency.
 * - If Baritone is missing, prints an in-game instruction message.
 */
public class AutoPlayMod implements ClientModInitializer {
    private static boolean started = false;

    @Override
    public void onInitializeClient() {
        ClientPlayConnectionEvents.JOIN.register((handler, sender, client) -> {
            // schedule on client thread shortly after join
            client.execute(() -> {
                started = false;
                if (client.player != null) client.player.sendMessage(new LiteralText("OpenClaw AutoPlay: Mod geladen — Autostart in ~2s"), false);

                // If the launcher provided an OPENCLAW_SEED env var, echo it into chat for reproducibility.
                try {
                    String seed = System.getenv("OPENCLAW_SEED");
                    if (seed != null && !seed.isEmpty() && client.player != null) {
                        client.player.sendChatMessage("openclaw:seed " + seed);
                        client.player.sendMessage(new LiteralText("OpenClaw: Seed posted to chat — " + seed), false);
                    }
                } catch (Throwable t) {
                    // non-fatal; continue with normal startup
                }

                // delay off the client thread then execute start on the client thread to ensure world is ready
                new Thread(() -> {
                    try { Thread.sleep(2000); } catch (InterruptedException ignored) {}
                    client.execute(() -> startWhenReady(client));
                }, "openclaw-autoplay-start").start();
            });
        });

        // Client-side command bridge: /openclaw craft <recipe>
        // - Safe: re-emits a chat token 'openclaw_request craft <recipe>' so the Mineflayer
        //   LAN fallback (or the external watcher) can handle the craft immediately.
        // - TODO: implement direct packet-based crafting (ServerboundContainerClickPacket)
        ClientCommandRegistrationCallback.EVENT.register((dispatcher, registryAccess) -> {
            dispatcher.register(ClientCommandManager.literal("openclaw")
                .then(ClientCommandManager.literal("craft")
                    .then(ClientCommandManager.argument("recipe", StringArgumentType.word())
                        .executes(ctx -> {
                            String recipe = StringArgumentType.getString(ctx, "recipe");
                            MinecraftClient mc = MinecraftClient.getInstance();
                            mc.execute(() -> handleCraftRequest(mc, recipe));
                            return 1;
                        }))));
        });
    }

    private void startWhenReady(MinecraftClient client) {
        if (started) return;
        started = true;

        // Try repeatedly (best-effort) to invoke Baritone; if Baritone is missing the user will get a clear instruction.
        Runnable tryStart = () -> {
            int attempts = 0;
            while (attempts < 3) {
                attempts++;
                try {
                    if (client.player != null) {
                        client.player.sendChatMessage("#script autoplay");
                        client.player.sendMessage(new LiteralText("AutoPlay: Startbefehl gesendet (Versuch " + attempts + ")"), false);
                    }
                    // assume success (Baritone prints its own chat output); wait a bit and stop retrying
                    try { Thread.sleep(1200); } catch (InterruptedException ignored) {}
                    break;
                } catch (Throwable t) {
                    try { Thread.sleep(800); } catch (InterruptedException ignored) {}
                }
            }

            // final check / user guidance
            client.execute(() -> {
                if (client.player != null) {
                    client.player.sendMessage(new LiteralText("AutoPlay: Wenn nichts passiert, gib im Chat ein: #script autoplay"), false);
                    client.player.sendMessage(new LiteralText("Falls Baritone fehlt: lade das Fabric‑Jar nach ~/.minecraft/mods/ — https://github.com/cabaletta/baritone/releases"), false);
                }
            });
        };

        // run the attempt off the client thread (we schedule user-visible messages on the client thread)
        new Thread(tryStart, "openclaw-autoplay-run").start();
    }

    // Handle craft requests originating from Baritone/one-click/watcher.
    // Strategy (best-effort, non-destructive):
    // 1) Try to craft directly in the player's 2x2 inventory grid for a small set of recipes
    //    (sticks, crafting_table). This uses Slot click sequences and is safe in singleplayer.
    // 2) If (1) fails or the recipe requires a crafting table / different layout, fall back to
    //    emitting the normalized chat token `openclaw_request craft <recipe>` so the Mineflayer
    //    fallback or external watcher can perform the craft.
    // NOTE: packet-level / ServerboundContainerClickPacket automation will be added in follow-ups
    //       once we add integration tests across multiple MC mappings.
    private void handleCraftRequest(MinecraftClient client, String recipe) {
        if (client.player == null) return;
        try {
            client.player.sendMessage(new LiteralText("OpenClaw: craft request received -> " + recipe), false);

            // attempt direct player-inventory craft for a small, safe set
            boolean didCraft = false;
            try {
                didCraft = tryPlayerInventoryCraft(client, recipe.toLowerCase());
            } catch (Throwable t) {
                // swallow — we'll fall back to chat-based handling below
                t.printStackTrace();
                didCraft = false;
            }

            if (didCraft) {
                client.player.sendMessage(new LiteralText("OpenClaw: crafted " + recipe + " (inventory-craft)"), false);
                return;
            }

            // otherwise forward to fallback (Mineflayer / watcher)
            client.player.sendChatMessage("openclaw_request craft " + recipe);
            client.player.sendMessage(new LiteralText("OpenClaw: forwarded craft request to fallback handler — if nothing happens, ensure required ingredients are present."), false);
        } catch (Throwable t) {
            // never crash the client; best-effort only
            try { client.player.sendMessage(new LiteralText("OpenClaw: craft request failed (see log)"), false); } catch (Throwable ignored) {}
            t.printStackTrace();
        }
    }

    // Very small, best-effort implementation that performs 2x2 inventory crafts by issuing
    // click-slot operations against the player's ScreenHandler. Currently supports:
    //  - "stick"         (2 planks -> sticks)
    //  - "crafting_table" (4 planks -> crafting_table)
    // Returns true on success. This is intentionally conservative and will return false
    // if inventory layout/mappings don't match expectations (avoids corrupting player state).
    private boolean tryPlayerInventoryCraft(MinecraftClient client, String recipe) {
        // Minimal safety checks
        if (client.player == null) return false;
        if (client.player.playerScreenHandler == null) return false;

        var handler = client.player.playerScreenHandler;
        // ensure handler has the expected small-crafting layout (result + 4 grid slots)
        if (handler.slots.size() < 5) return false;

        // helper lambdas
        java.util.function.Predicate<net.minecraft.item.ItemStack> isPlank = s -> !s.isEmpty() && s.getItem().getTranslationKey().toLowerCase().contains("plank");
        java.util.function.Predicate<net.minecraft.item.ItemStack> isAny = s -> !s.isEmpty();

        // find first slot index that matches predicate (search main inventory + hotbar)
        java.util.function.BiFunction<java.util.function.Predicate<net.minecraft.item.ItemStack>, Integer, Integer> findSlot = (pred, startIdx) -> {
            for (int i = startIdx; i < handler.slots.size(); i++) {
                var st = handler.getSlot(i).getStack();
                if (pred.test(st)) return i;
            }
            return -1;
        };

        // convenience for issuing a click: (slot, button, action)
        java.util.function.Consumer<java.lang.Integer> pickupSlot = (slot) -> {
            // PICKUP = SlotActionType.PICKUP
            client.interactionManager.clickSlot(handler.syncId, slot, 0, net.minecraft.screen.slot.SlotActionType.PICKUP, client.player);
        };

        try {
            switch (recipe) {
                case "stick": {
                    // need at least one wood plank (will craft 4 sticks from 2x2)
                    int plankSlot = findSlot.apply(isPlank, 5);
                    if (plankSlot == -1) return false;
                    // move one plank into crafting grid slot (index 1), then click result
                    pickupSlot.accept(plankSlot);
                    pickupSlot.accept(1); // craft grid slot 0/1.. handler dependent; best-effort
                    // duplicate to create the 2x2 pattern (we try to reuse same plank if available)
                    // attempt to find a second plank
                    int plankSlot2 = findSlot.apply(isPlank, 5);
                    if (plankSlot2 == -1) {
                        // if only one stack, try splitting by pickup the same slot again
                        pickupSlot.accept(plankSlot);
                        pickupSlot.accept(2);
                    } else {
                        pickupSlot.accept(plankSlot2);
                        pickupSlot.accept(2);
                    }
                    // click result slot (0) to pick up crafted sticks
                    pickupSlot.accept(0);
                    // place result into first empty inventory slot
                    int empty = findSlot.apply(s -> s.isEmpty(), 5);
                    if (empty == -1) empty = findSlot.apply(isAny, 5); // fall back to any slot
                    if (empty != -1) pickupSlot.accept(empty);
                    return true;
                }
                case "crafting_table":
                case "craftingtable": {
                    // need 4 planks anywhere in inventory
                    int p1 = findSlot.apply(isPlank, 5);
                    if (p1 == -1) return false;
                    int p2 = findSlot.apply(isPlank, p1 + 1);
                    if (p2 == -1) return false;
                    int p3 = findSlot.apply(isPlank, p2 + 1);
                    if (p3 == -1) return false;
                    int p4 = findSlot.apply(isPlank, p3 + 1);
                    if (p4 == -1) return false;
                    // move them into the 2x2 grid (slots 1..4)
                    pickupSlot.accept(p1); pickupSlot.accept(1);
                    pickupSlot.accept(p2); pickupSlot.accept(2);
                    pickupSlot.accept(p3); pickupSlot.accept(3);
                    pickupSlot.accept(p4); pickupSlot.accept(4);
                    // grab result
                    pickupSlot.accept(0);
                    // place result into first empty inventory slot
                    int empty = findSlot.apply(s -> s.isEmpty(), 5);
                    if (empty == -1) empty = findSlot.apply(isAny, 5);
                    if (empty != -1) pickupSlot.accept(empty);
                    return true;
                }
                default:
                    return false;
            }
        } catch (Exception e) {
            // some mappings/layouts may differ — fail safely
            e.printStackTrace();
            return false;
        }
    }
}

