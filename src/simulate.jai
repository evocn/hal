// Hal
// Simulate
// Alex Hartford
// September 2023

// The Core Simulation Logic
simulate :: (guy: *Guy, level: *Level, dt: float) {
    if #complete current_scene == {
        case .GAME;
            resolve_game_inputs(guy, level.*, dt);
            update(guy, dt);

            // Super Hacky. @TODO: Clean this up.
            if collision(guy.collision_box, Rect.{.{xx (TILE_SIZE * level.end.x) + 7.0, xx (TILE_SIZE * level.end.y) + 7.0}, .{2, 2}}) {
                load_and_initialize_level(level, guy, level.next_level_name);
            }

            if guy.dead {
                load_and_initialize_level(level, guy, level.shortname);
            }

            make_tiles_disappear :: (level: *Level) {
                for tiles, col: level.columns {
                    for tile, row: tiles {
                        if tile.should_disappear {
                            set_tile(level, .{col, row}, 0);
                        }
                    }
                }
            }
            make_tiles_disappear(level);

        case .MENU;
            resolve_menu_inputs(*menu);

        case .EDITOR;
            resolve_editor_inputs(level, dt);
    }
}

//
//

resolve_game_inputs :: (guy: *Guy, level: Level, dt: float) {
    if button_was_just_pressed(.START) {
        switch_scene(.MENU);
    }

    resolve_player_inputs(guy, level, dt);
}
