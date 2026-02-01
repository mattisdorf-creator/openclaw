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
    // Current behaviour: • emit a chat token that the Mineflayer fallback understands
    //                    • show an in-game confirmation to the player
    // Future: replace with direct, packet-based crafting for fully offline automation.
    private void handleCraftRequest(MinecraftClient client, String recipe) {
        if (client.player == null) return;
        try {
            client.player.sendMessage(new LiteralText("OpenClaw: craft request received -> " + recipe), false);
            // Re-emit as a normalized chat token so existing fallbacks react the same way.
            client.player.sendChatMessage("openclaw_request craft " + recipe);

            // Quick local hints for common recipes (helpful for debugging / visual feedback)
            switch (recipe.toLowerCase()) {
                case "bucket":
                    client.player.sendMessage(new LiteralText("OpenClaw: ensure a crafting table is available (bucket needs 3 iron)."), false);
                    break;
                case "crafting_table":
                case "craftingtable":
                    client.player.sendMessage(new LiteralText("OpenClaw: attempting player-craft (if 4 planks present)."), false);
                    break;
                case "stick":
                    client.player.sendMessage(new LiteralText("OpenClaw: attempting quick craft for sticks."), false);
                    break;
                default:
                    client.player.sendMessage(new LiteralText("OpenClaw: craft request forwarded — fallback handler will attempt it."), false);
            }
        } catch (Throwable t) {
            // never crash the client; best-effort only
            try { client.player.sendMessage(new LiteralText("OpenClaw: craft request failed (see log)"), false); } catch (Throwable ignored) {}
            t.printStackTrace();
        }
    }
}
