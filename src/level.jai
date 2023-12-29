// Hal
// Level
// Alex Hartford
// December 2023

Level :: struct {
    height  :: VIEWPORT_HEIGHT_IN_TILES;
    width   :: VIEWPORT_WIDTH_IN_TILES;

    tiles: [height * width] Tile;
    platforms: [..] Platform;
    npcs: [..] NPC;

    start: Pair;
    end  : Pair;

    name : string;
}

update :: (level: *Level, dt: float) {
    for level.platforms {
        update(*it, dt);
    }

    for level.npcs {
        update(*it, dt);
    }
}


current_level_index : int;
level_names := string.[
    "01",
    "02",
    "03",
    "04",
    "05",
    "06",
    "07",
    "08",
    "09",
    "10",
    "11",
    "12",
    "13",
    "14",
    "15",
    "16",
    "17",
    "18",
    "19",
    "20",
];

switch_to_next_level :: () -> string {
    current_level_index += 1;
    if current_level_index >= level_names.count {
        current_level_index = 0;
    }
    return level_names[current_level_index];
}


load_and_initialize_level :: (level: *Level, player: *Player, name: string) -> success: bool {
    success := load_level(level, name);

    reset_simulation();

    // Add Solids
    {
        // Tiles
        for tile : level.tiles {
            if tile.properties.kind == .COLLECTIBLE {
                array_add(*simulation.collectibles, *tile.collectible);
            }
            else if tile.properties.kind == .HAZARD {
                array_add(*simulation.hazards, *tile.hazard);
            }
            else if tile.properties.kind == .SOLID {
                array_add(*simulation.solids, *tile.solid);
            }
        }

        // Add Platforms
        for platform : level.platforms {
            array_add(*simulation.solids, *platform.solid);
        }
    }

    // Add Actors
    {
        array_add(*simulation.actors, *player.actor);
    }

    // Reset Player
    {
        move_here_dumb(player, level.start.x * TILE_SIZE_IN_PIXELS, level.start.y * TILE_SIZE_IN_PIXELS);
        neutralize(player);
    }

    return success;
}

wipe :: (level: *Level) {
    for * level.tiles {
        it.* = .{};
    }

    array_reset(*level.platforms);
    array_reset(*level.npcs);

    level.start = .{0, 0};
    level.end   = .{1, 0};
}
