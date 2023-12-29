// Mak
// NPC
// Alex Hartford
// December 2023

NPC :: struct {
    kind : NPC_Kind;
    sprite: int;
    tile  : Pair;

    speech: string;
    speech_progress: float;
    speech_speed : float = 0.2;

    trigger_box: Collider;

    animation: Animation;
    color := purple;
}

NPC_Kind :: enum {
    FROG;
    MOUSE;
    SNAIL;
    DOG;
}

update :: (npc: *NPC, dt: float) {
    update(*npc.animation, dt);
    npc.sprite = get_value(npc.animation);

    npc.speech_progress += npc.speech_speed * dt;
    clamp(npc.speech_progress, 0, 1.0);
}

Frog :: struct {
    using #as npc: NPC;
    kind = .FROG;
    speech = "Ribbit";
}

make_frog :: (tile: Pair, collider: Collider) -> Frog {
    frog : Frog;
    frog.tile = tile;
    frog.trigger_box = collider;

    {
        frog.animation = 
            animation_make(
                name = "idle",
                value = *frog.sprite,
                duration = 1.0,
                .{0.0, 48},
                .{0.5, 49},
            );
        start(*frog.animation);
    }

    return frog;
}
