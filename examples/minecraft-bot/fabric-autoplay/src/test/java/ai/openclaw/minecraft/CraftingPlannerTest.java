package ai.openclaw.minecraft;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

public class CraftingPlannerTest {
    @Test
    void compute2x2GridSlots_basic() {
        List<Integer> slots = CraftingPlanner.compute2x2GridSlots(9, 36);
        assertEquals(4, slots.size());
        assertEquals(List.of(9, 10, 11, 12), slots);
    }

    @Test
    void compute2x2GridSlots_tooSmall() {
        List<Integer> slots = CraftingPlanner.compute2x2GridSlots(34, 36);
        assertTrue(slots.isEmpty());
    }

    @Test
    void findFirstN_returnsN() {
        boolean[] occupied = new boolean[] { false, true, true, false, true };
        var r = CraftingPlanner.findFirstN(occupied, 2);
        assertEquals(List.of(1, 2), r);
    }
}
