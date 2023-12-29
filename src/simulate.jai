// Hal
// Simulate
// Alex Hartford
// September 2023

// The Core Simulation Logic

Simulation :: struct {
    actors : [..] *Actor;
    solids : [..] *Solid;
    collectibles : [..] *Collectible;
    hazards : [..] *Hazard;
}

simulation : Simulation;

reset_simulation :: () {
    array_reset(*simulation.actors);
    array_reset(*simulation.solids);
    array_reset(*simulation.collectibles);
    array_reset(*simulation.hazards);
}

////////////////////////////////////////////////////////////////////////////////

update :: (input: Input, player: *Player, level: *Level, dt: float) {
    if #complete current_scene == {
        case .GAME;
            if button_was_just_pressed(input, .START) {
                switch_scene(.MENU);
            }

            update(level, dt);

            update(player, level.*, dt);

            resolve_player_inputs(input, player);
            resolve_player_inputs_for_appearance(input, player);

            {
                for * npc: level.npcs {
                    if !collision(player.collider, npc.trigger_box) {
                        npc.speech_progress = 0;
                    }
                }
            }

            {
                // Level stuff
                if collision(player.collider, Collider.{TILE_SIZE_IN_PIXELS * level.end.x + 7, TILE_SIZE_IN_PIXELS * level.end.y + 7, 2, 2}) {
                    next_level_name := switch_to_next_level();
                    load_and_initialize_level(level, player, next_level_name);
                }

                if player.dead {
                    load_and_initialize_level(level, player, level.name);
                }

                // Rid ourselves of collectibles
                for * tile : level.tiles {
                    if tile.kind == .COLLECTIBLE && tile.collectible.collected {
                        if tile.collectible.kind == {
                            case .COIN; game_state.coins += 1;
                            case .GEM;  game_state.coins += 5;
                        }

                        col := it_index % level.width;
                        row := it_index / level.width;
                        tile.* = generate_tile(col, row, 0);
                    }
                }
            }

        case .MENU;
            resolve_menu_inputs(input, *menu);

        case .EDITOR;
            resolve_editor_inputs(input, level, dt);
    }
}

filter_irrelevant_solids :: (solids: [..] *Solid, actor: Actor) -> [] *Solid {
    result : [..] *Solid;
    result.allocator = temp;

    for solid : solids {
        if solid.one_way {
            if solid.collider.y + solid.collider.height <= actor.collider.y {
                array_add(*result, solid);
            }
        }
        else {
            array_add(*result, solid);
        }
    }

    return result;
}
