package ai.openclaw.minecraft;

import java.util.ArrayList;
import java.util.List;

/**
 * Small pure‑Java helper for computing safe 2x2 inventory slot placements.
 * Kept dependency‑free so it can be unit tested without Minecraft mappings.
 */
public final class CraftingPlanner {
    private CraftingPlanner() {}

    /**
     * Compute a conservative 2x2 slot layout for a player's inventory handler.
     * - mainInventoryStart is the index where main inventory (including hotbar) begins in the handler
     * - handlerSize is total slot count (used only for bounds checks)
     *
     * Returns a list of 4 target slot indices for the 2x2 grid (row-major). If there is
     * insufficient space, returns an empty list.
     */
    public static List<Integer> compute2x2GridSlots(int mainInventoryStart, int handlerSize) {
        List<Integer> out = new ArrayList<>(4);
        // conservative: choose the first four slots starting at mainInventoryStart
        if (handlerSize - mainInventoryStart < 4) return out;
        out.add(mainInventoryStart);
        out.add(mainInventoryStart + 1);
        out.add(mainInventoryStart + 2);
        out.add(mainInventoryStart + 3);
        return out;
    }

    /**
     * Simple helper to find the first N slot indices with a predicate applied to an array of booleans.
     * Provided so tests can simulate inventory layouts.
     */
    public static List<Integer> findFirstN(boolean[] occupied, int n) {
        List<Integer> out = new ArrayList<>(n);
        for (int i = 0; i < occupied.length && out.size() < n; i++) {
            if (occupied[i]) out.add(i);
        }
        return out;
    }
}
