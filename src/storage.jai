// Hal
// Storage
// Alex Hartford
// October 2023

LEVELS_PATH :: "levels";
BACKUPS_PATH :: "levels/backups";

load_and_initialize_level :: (level: *Level, guy: *Guy, shortname: string) -> success: bool {
    success := load_level(level, shortname);
    move_here_dumb(guy, convert_to_vector(level.start * 16));
    neutralize(guy);
    return success;
}

load_level :: (level: *Level, shortname: string) -> success: bool {
    full_path := tprint("%/%.level", LEVELS_PATH, shortname);

    handler: Text_File_Handler;
    defer deinit(*handler);
    handler.do_version_number = false;

    start_file(*handler, shortname, full_path);
    if handler.failed {
        log_error("File handler failed to start file!\n");
        return false;
    }

    // Reset Level
    array_reset(*level.columns);
    array_reset(*level.wind_streams);

    // Parse Level file and populate struct
    line, found := consume_next_line(*handler);
    assert(found);
    for 0..line.count-1  _ := array_add(*level.columns);

    for row: 0..LEVEL_HEIGHT-1 {
        for character, col : cast([] u8)line {
            assert(is_digit(character));
            catalogue_index := character - #char "0";
            set_tile(level, .{col, row}, catalogue_index);
        }

        line, found = consume_next_line(*handler);
    }

    line, found = consume_next_line(*handler);
    while line != "---" {
        strs := split(line, " ");
        array_add(*level.wind_streams, Wind_Stream.{.{string_to_int(strs[0]), string_to_int(strs[1])}, string_to_int(strs[2]), string_to_float(strs[3])});

        line, found = consume_next_line(*handler);
    }

    success : bool;
    level.start, success = parse_int_pair(*handler);
    assert(success);

    level.end, success = parse_int_pair(*handler);
    assert(success);

    level.shortname = copy_string(shortname);

    next_level_name:, success = consume_next_line(*handler);
    level.next_level_name = copy_string(next_level_name);

    if handler.failed {
        log_error("File handler failed parsing somewhere!\n");
        return false;
    }

    dprint_once(sprint("Loaded Level %", level.shortname));

    return true;
}

save_level :: (level: Level, shortname: string) -> success: bool {
    builder : String_Builder;
    defer free_buffers(*builder);

    // Print Tiles
    for row : 0..LEVEL_HEIGHT-1 {
        for col : 0..level.columns.count-1 {
            tile := level.columns[col][row];
            print_to_builder(*builder, "%", tile.index);
        }
        append(*builder, "\n");
    }

    append(*builder, "---\n");

    for level.wind_streams {
        print_to_builder(*builder, "% % % %\n", it.direction.x, it.direction.y, it.row_or_column_based_on_direction, it.strength);
    }

    append(*builder, "---\n");

    print_to_builder(*builder, "% % # Start\n", level.start.x, level.start.y);
    print_to_builder(*builder, "% % # End\n",   level.end.x, level.end.y);
    print_to_builder(*builder, "% # Next\n",   level.next_level_name);

    full_path := tprint("%/%.level", LEVELS_PATH, shortname);
    success := write_entire_file(full_path, *builder);

    if !success {
        log_error("Couldn't write to file %!\n", full_path);
        return false;
    }

    dprint_once(sprint("Saved Level %", shortname));

    t := get_system_time();
    backup_full_path := tprint("%/%-%.level", BACKUPS_PATH, shortname, tprint("%_%_%_%_%", t.year, t.month, t.day, t.hour, t.minute));
    success = write_entire_file(backup_full_path, *builder);

    if !success {
        log_error("Couldn't write to backup file %!\n", backup_full_path);
        return false;
    }

    return true;
}
