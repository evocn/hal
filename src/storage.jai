// Hal
// Storage
// Alex Hartford
// October 2023

LEVELS_PATH :: "levels";
BACKUPS_PATH :: "levels/backups";

expect_and_consume_section_separator :: (handler: *Text_File_Handler) {
    line, found := consume_next_line(handler);
    assert(found);
    assert(line == "---");
}

load_level :: (level: *Level, name: string) -> success: bool {
    full_path := tprint("%/%.level", LEVELS_PATH, name);

    handler: Text_File_Handler;
    defer deinit(*handler);
    handler.do_version_number = false;

    start_file(*handler, name, full_path);
    if handler.failed {
        log_error("File handler failed to start file!\n");
        return false;
    }

    wipe(level);
    level.name = copy_string(name);

    // Tiles
    {
        for row : 0..level.height-1 {
            line, found := consume_next_line(*handler);
            assert(found);

            for character, col : cast([] u8)line {
                assert(is_digit(character));
                catalogue_index := character - #char "0";
                generate_and_set_tile(level, col, row, catalogue_index);
            }
        }
    }

    expect_and_consume_section_separator(*handler);

    // Level Start / End
    {
        success : bool;

        level.start, success = parse_int_pair(*handler);
        assert(success);

        level.end, success = parse_int_pair(*handler);
        assert(success);
    }

    expect_and_consume_section_separator(*handler);

    // Miscellaneous Elements
    {
        line, found := consume_next_line(*handler);
        while found {
            args := split(line, " ");

            if args[0] == {
                case "platform";
                    platform := array_add(*level.platforms);
                    initialize_platform(
                        platform, 
                        width   = string_to_int(args[1]),
                        height  = string_to_int(args[2]),
                        points = .[
                            .{
                                string_to_int(args[3]),
                                string_to_int(args[4]),
                            },
                            .{
                                string_to_int(args[5]),
                                string_to_int(args[6]),
                            }
                        ], 
                        speed = string_to_float(args[7]),
                        easing_function_identifier = cast(Easing_Function_Identifier)string_to_int(args[8]),
                    );

                case "frog";
                    x := string_to_int(args[1]);
                    y := string_to_int(args[2]);

                    frog := make_frog(
                        .{x, y},
                        Collider.{
                            x * TILE_SIZE_IN_PIXELS - 32,
                            y * TILE_SIZE_IN_PIXELS,
                            64,
                            32,
                        },
                    );

                    array_add(*level.npcs, frog);

                case "npc";
                    x := string_to_int(args[2]);
                    y := string_to_int(args[3]);

                    kind := cast(NPC_Kind)(string_to_int(args[1]));
                    if kind == {
                        case .FROG;
                            frog := make_frog(
                                .{x, y},
                                Collider.{
                                    x * TILE_SIZE_IN_PIXELS - 32,
                                    y * TILE_SIZE_IN_PIXELS,
                                    64,
                                    32,
                                },
                            );

                            array_add(*level.npcs, frog);

                        case .MOUSE;

                        case .SNAIL;

                        case .DOG;

                    }
            }

            line, found = consume_next_line(*handler);
        }
    }



    if handler.failed {
        log_error("File handler failed parsing somewhere!\n");
        return false;
    }

    dprint_once(sprint("Loaded Level %", level.name));

    return true;
}

save_level :: (level: Level, name: string) -> success: bool {
    builder : String_Builder;
    defer free_buffers(*builder);

    // Tiles
    {
        for row : 0..level.height-1 {
            for col : 0..level.width-1 {
                tile_catalogue_index := level.tiles[row * level.width + col].catalogue_index;
                print_to_builder(*builder, "%", tile_catalogue_index);
            }
            append(*builder, "\n");
        }
    }

    append(*builder, "---\n");

    // Level Start / End
    {
        print_to_builder(*builder, "% % # Start\n", level.start.x, level.start.y);
        print_to_builder(*builder, "% % # End\n",   level.end.x, level.end.y);
    }

    append(*builder, "---\n");

    // Miscellaneous Elements
    {
        for level.platforms {
            print_to_builder(*builder, "platform % % % % % % % %  # width, height, points[0], points[1], speed, easing\n", 
                it.width, it.height, 
                it.points[0].x, it.points[0].y, 
                it.points[1].x, it.points[1].y, 
                it.speed, cast(int)it.easing_function_identifier,
            );
        }

        for level.npcs {
            print_to_builder(*builder, "npc % % %  # kind, x, y\n",
                cast(int)it.kind,
                it.tile.x, 
                it.tile.y,
            );
        }
    }

    raw_text := builder_to_string(*builder, temp);

    // Write to the Level file.
    {
        full_path := tprint("%/%.level", LEVELS_PATH, name);
        success := write_entire_file(full_path, raw_text);

        if !success {
            log_error("Couldn't write to file %!\n", full_path);
            return false;
        }

        dprint_once(sprint("Saved Level %", name));
    }

    // Write to the backup file.
    {
        t := get_system_time();
        backup_full_path := tprint("%/%-%.level", BACKUPS_PATH, name, tprint("%_%_%_%_%", t.year, t.month, t.day, t.hour, t.minute));
        success := write_entire_file(backup_full_path, raw_text);

        if !success {
            log_error("Couldn't write to backup file %!\n", backup_full_path);
            return false;
        }
    }

    return true;
}
