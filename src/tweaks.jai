// Mak
// Tweaks
// Alex Hartford
// October 2023

save_tweaks_file :: (file_name : string) {
    builder : String_Builder;
    defer free_buffers(*builder);

    append(*builder, "# Tweaks file\n\n");

    print_to_builder(*builder, "level %\n", current_level_index);

    print_to_builder(*builder, "fullscreen %\n", fullscreen);

    print_to_builder(*builder, "sfx %\n", ma_sound_group_get_volume(*audio_context.sfx_group));
    print_to_builder(*builder, "music %\n", ma_sound_group_get_volume(*audio_context.music_group));
    print_to_builder(*builder, "ambience %\n", ma_sound_group_get_volume(*audio_context.ambience_group));

    full_path := tprint("%/%.tweaks", tweaks_path, file_name);
    write_entire_file(full_path, *builder);
}

load_tweaks_file_and_apply_results :: (file_name : string) -> file_exists: bool {
    handler : Text_File_Handler;
    defer deinit(*handler);
    handler.do_version_number = false;

    full_path := tprint("%/%.tweaks", tweaks_path, file_name);
    start_file(*handler, file_name, full_path);
    if handler.failed return false;

    line, found := consume_next_line(*handler);

    while found {
        successfully_split, left, right := split_from_left(line, #char " ");
        if !successfully_split {
            log_error("Problem parsing the tweaks file!\n");
            return false;
        }

        successfully_parsed : bool;
        if left == {
            case "level";
                current_level_index, successfully_parsed = parse_int(*right);

            case "fullscreen";
                fullscreen, successfully_parsed = parse_bool(*right);
                set_screen_mode_according_to_fullscreen_variable();

            case "sfx";
                sfx_volume :, successfully_parsed = parse_float(*right);
                set_sfx_volume(sfx_volume);

            case "music";
                music_volume:, successfully_parsed = parse_float(*right);
                set_music_volume(music_volume);

            case "ambience";
                ambience_volume :, successfully_parsed = parse_float(*right);
                set_ambience_volume(ambience_volume);
        }
        if !successfully_parsed {
            log_error("Problem parsing the tweaks file!\n");
            return false;
        }

        line, found = consume_next_line(*handler);
    }

    return true;
}


apply_default_settings :: () {
    DEFAULT_SFX_VOLUME :: 1.0;
    DEFAULT_MUSIC_VOLUME :: 1.0;
    DEFAULT_AMBIENCE_VOLUME :: 1.0;
    fullscreen = false;
    current_level_index = 0;

    set_screen_mode_according_to_fullscreen_variable();

    set_sfx_volume(DEFAULT_SFX_VOLUME);
    set_music_volume(DEFAULT_MUSIC_VOLUME);
    set_ambience_volume(DEFAULT_AMBIENCE_VOLUME);
}
