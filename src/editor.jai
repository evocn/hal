// Mak
// Editor
// Alex Hartford
// September 2023

editor : struct {
    cursor : Pair;
    current_tile_painting_catalogue_index : int = 1;
    current_wind_stream_index : int = -1;
    should_save : bool;
    should_reload : bool;
    should_make_new_level : bool;
}

reset_editor_state :: () {
    using editor;

    cursor = .{};
    current_tile_painting_catalogue_index = 1;
    current_wind_stream_index = -1;
    should_save = false;
    should_reload = false;
    should_make_new_level = false;
}

resolve_editor_inputs :: (level: *Level, dt: float) {
    using input;

    if button_was_just_pressed(.LEFT) {
        editor.cursor += .{-1, 0};
        editor.cursor.x = clamp(editor.cursor.x, 0, VIEWPORT_WIDTH-1);
    }

    if button_was_just_pressed(.RIGHT) {
        editor.cursor += .{1, 0};
        editor.cursor.x = clamp(editor.cursor.x, 0, VIEWPORT_WIDTH-1);
    }

    if button_was_just_pressed(.DOWN) {
        editor.cursor += .{0, -1};
        editor.cursor.y = clamp(editor.cursor.y, 0, VIEWPORT_HEIGHT-1);
    }

    if button_was_just_pressed(.UP) {
        editor.cursor += .{0, 1};
        editor.cursor.y = clamp(editor.cursor.y, 0, VIEWPORT_HEIGHT-1);
    }

    if button_was_just_pressed(.A) {
        set_tile(level, editor.cursor, editor.current_tile_painting_catalogue_index);
    }

    if button_was_just_pressed(.B) {
        set_tile(level, editor.cursor, 0);
    }

    if button_was_just_pressed(.START) {
        level.start = editor.cursor;
    }

    if button_was_just_pressed(.SELECT) {
        level.end = editor.cursor;
    }
}

update_and_draw_editor :: (level: *Level, guy: *Guy) {
    io := ImGui.GetIO();
    program_state.imgui_capturing_mouse    = io.WantCaptureMouse;
    program_state.imgui_capturing_keyboard = io.WantCaptureKeyboard;
    program_state.framerate = io.Framerate;

    ImGui_ImplSdl_NewFrame(window);
    ImGui.NewFrame();
    {
        file_editor(level, guy);
        level_editor(level, guy);

        controls_display();

        //ImGui.ShowDemoWindow();
    }
    ImGui.Render();

    if editor.should_save {
        editor.should_save = false;
        save_level(level.*, level.shortname);
    }
    if editor.should_reload {
        editor.should_reload = false;
        load_and_initialize_level(level, guy, level.shortname);
    }
    if editor.should_make_new_level {
        editor.should_make_new_level = false;
        save_level(level.*, "new");
        load_and_initialize_level(level, guy, "new");
    }
}

////////////////////////////////////////////////////////////////////////////////
// Specific Editors
//

goto_buffer : [64] u8;
shortname_buffer : [64] u8;
next_level_name_buffer : [64] u8;

file_editor :: (level: *Level, guy: *Guy) {
    ImGui.Begin("File", null, .ImGuiWindowFlags_AlwaysAutoResize);
    {
        if ImGui.Button("Save") {
            save_level(level.*, level.shortname);
        }
        ImGui.SameLine();
        if ImGui.Button("Load") {
            load_and_initialize_level(level, guy, level.shortname);
        }
        ImGui.SameLine();
        if ImGui.Button("New") {
            save_level(level.*, "new");
            load_and_initialize_level(level, guy, "new");
        }
        ImGui.SameLine();
        if ImGui.Button("Wipe") {
            wipe(level);
        }

        ImGui.Text("Current: %", level.shortname);
        ImGui.SameLine();
        if ImGui.InputText("#### New", shortname_buffer.data, shortname_buffer.count, flags=.EnterReturnsTrue | .EscapeClearsAll | .AutoSelectAll) {
            if level.shortname == "new" {
                success := file_delete(tprint("%/%.level", LEVELS_PATH, "new"));
                assert(success);
            }

            level.shortname = copy_string(to_string(shortname_buffer.data));
            memset(shortname_buffer.data, 0, shortname_buffer.count);

            save_level(level.*, level.shortname);
        }

        ImGui.Text("Next: %", level.next_level_name);
        ImGui.SameLine();
        if ImGui.InputText("#### Next", next_level_name_buffer.data, next_level_name_buffer.count, flags=.EnterReturnsTrue | .EscapeClearsAll | .AutoSelectAll) {
            level.next_level_name = copy_string(to_string(next_level_name_buffer.data));
            memset(next_level_name_buffer.data, 0, next_level_name_buffer.count);
        }

        ImGui.Text("Goto: ");
        ImGui.SameLine();
        if ImGui.InputText("#### Goto", goto_buffer.data, goto_buffer.count, flags=.EnterReturnsTrue | .EscapeClearsAll | .AutoSelectAll) {
            load_and_initialize_level(level, guy, to_string(goto_buffer.data));
            memset(goto_buffer.data, 0, goto_buffer.count);
        }
    }
    ImGui.End();
}

level_editor :: (level: *Level, guy: *Guy) {
    ImGui.Begin("Level", null, .ImGuiWindowFlags_AlwaysAutoResize);
    {
        if ImGui.BeginTabBar("Level Tabs")
        {
            if ImGui.BeginTabItem("Tiles") {
                ImGui.SliderInt("### Paint", xx *editor.current_tile_painting_catalogue_index, 1, xx (tile_catalogue.count - 1), temp_c_string(tprint("% - %", editor.current_tile_painting_catalogue_index, tile_catalogue[xx editor.current_tile_painting_catalogue_index].name)));

                ImGui.EndTabItem();
            }

            if ImGui.BeginTabItem("Wind") {
                if level.wind_streams.count {
                    if editor.current_wind_stream_index == -1 then editor.current_wind_stream_index = 0;
                    ImGui.SliderInt("### Stream", xx *editor.current_wind_stream_index, 0, xx (level.wind_streams.count-1));
                }
                if ImGui.Button("New") {
                    _ := array_add(*level.wind_streams);
                    editor.current_wind_stream_index = level.wind_streams.count-1;
                }
                if editor.current_wind_stream_index != -1 {
                    ImGui.SameLine();
                    if ImGui.Button("Delete") {
                        array_ordered_remove_by_index(*level.wind_streams, editor.current_wind_stream_index);
                        editor.current_wind_stream_index -= 1;
                    }

                    ImGui.NewLine();

                    wind_stream_editor(level);
                }

                ImGui.EndTabItem();
            }

            ImGui.EndTabBar();
        }
    }
    ImGui.End();
}

wind_stream_editor :: (level: *Level) {
    level_width := level.columns[0].count;
    level_height := LEVEL_HEIGHT;

    wind_stream := *level.wind_streams[editor.current_wind_stream_index];

    if ImGui.Button("Left") {
        wind_stream.direction = Left;
    }
    ImGui.SameLine();
    if ImGui.Button("Right") {
        wind_stream.direction = Right;
    }
    ImGui.SameLine();
    if ImGui.Button("Up") {
        wind_stream.direction = Up;
    }

    if wind_stream.direction == Up {
        ImGui.SliderInt("### Column", xx *wind_stream.row_or_column_based_on_direction, 0, xx (level_width - 1), temp_c_string(tprint("Column: %", wind_stream.row_or_column_based_on_direction)));
    }
    else {
        ImGui.SliderInt("### Row", xx *wind_stream.row_or_column_based_on_direction, 0, xx (level_height - 1), temp_c_string(tprint("Row: %", wind_stream.row_or_column_based_on_direction)));
    }

    ImGui.SliderFloat("### Strength", xx *wind_stream.strength, 0.0, xx 10.0, temp_c_string(tprint("Strength: %", wind_stream.strength)));
}

controls_display :: () {
    ImGui.Begin("Controls");
    {
        ImGui.Text("Move | WASD");
        ImGui.Text("Save | Z");
        ImGui.Text("Load | X");
        ImGui.Text("Paint | Space");
        ImGui.Text("Erase | LShift");
        ImGui.Text("Move Start | Enter");
        ImGui.Text("Move End   | Esc");
    }
    ImGui.End();
}

//
// Utility Stuff ///////////////////////////////////////////////////////////////
//

imgui_flags_editor :: (flags: *$T) {
    ti := type_info(T);
    assert(ti.type == .ENUM);

    selections: [..] bool;
    selections.count = ti.values.count;
    selections.data = cast(*bool)alloc(ti.values.count);
    memset(selections.data, 0, ti.values.count);
    defer array_reset(*selections);

    for ti.values {
        if flags.* & cast(T)it {
            selections[it_index] = true;
        }
    }

    for ti.names {
        ImGui.Selectable(temp_c_string(it), *selections[it_index]);
    }

    flags.* = 0;
    for ti.values {
        if selections[it_index] {
            flags.* |= cast(T)it;
        }
    }
}

