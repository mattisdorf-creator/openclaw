package ai.openclaw.minecraft;

import net.fabricmc.api.ClientModInitializer;
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
}
