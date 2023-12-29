// Mak
// Editor
// Alex Hartford
// September 2023

editor : struct {
    cursor : Pair;
    current_tile_painting_catalogue_index : int = 1;
    current_platform_index : int = -1;
    should_save : bool;
    should_reload : bool;
    should_make_new_level : bool;
}

reset_editor_state :: () {
    using editor;

    cursor = .{};
    current_tile_painting_catalogue_index = 1;
    current_platform_index = -1;
    should_save = false;
    should_reload = false;
    should_make_new_level = false;
}

resolve_editor_inputs :: (input: Input, level: *Level, dt: float) {
    if button_was_just_pressed(input, .LEFT) {
        editor.cursor += .{-1, 0};
        editor.cursor.x = clamp(editor.cursor.x, 0, VIEWPORT_WIDTH_IN_TILES-1);
    }

    if button_was_just_pressed(input, .RIGHT) {
        editor.cursor += .{1, 0};
        editor.cursor.x = clamp(editor.cursor.x, 0, VIEWPORT_WIDTH_IN_TILES-1);
    }

    if button_was_just_pressed(input, .DOWN) {
        editor.cursor += .{0, -1};
        editor.cursor.y = clamp(editor.cursor.y, 0, VIEWPORT_HEIGHT_IN_TILES-1);
    }

    if button_was_just_pressed(input, .UP) {
        editor.cursor += .{0, 1};
        editor.cursor.y = clamp(editor.cursor.y, 0, VIEWPORT_HEIGHT_IN_TILES-1);
    }

    if button_was_just_pressed(input, .A) {
        generate_and_set_tile(level, editor.cursor.x, editor.cursor.y, editor.current_tile_painting_catalogue_index);
    }

    if button_was_just_pressed(input, .B) {
        generate_and_set_tile(level, editor.cursor.x, editor.cursor.y, 0);
    }

    if button_was_just_pressed(input, .START) {
        level.start = editor.cursor;
    }

    if button_was_just_pressed(input, .SELECT) {
        level.end = editor.cursor;
    }
}

update_and_draw_editor :: (player: *Player, level: *Level) {
    io := ImGui.GetIO();
    program_state.imgui_capturing_mouse    = io.WantCaptureMouse;
    program_state.imgui_capturing_keyboard = io.WantCaptureKeyboard;
    program_state.framerate = io.Framerate;

    ImGui_ImplSdl_NewFrame(window);
    ImGui.NewFrame();
    {
        file_editor(level, player);
        level_editor(level, player);

        controls_display();

        //ImGui.ShowDemoWindow();
    }
    ImGui.Render();

    if editor.should_save {
        editor.should_save = false;
        save_level(level, level.name);
    }
    if editor.should_reload {
        editor.should_reload = false;
        load_and_initialize_level(level, player, level.name);
    }
    if editor.should_make_new_level {
        editor.should_make_new_level = false;
        save_level(level, "new");
        load_and_initialize_level(level, player, "new");
    }
}

////////////////////////////////////////////////////////////////////////////////
// Specific Editors
//

goto_buffer : [64] u8;

file_editor :: (level: *Level, player: *Player) {
    ImGui.Begin("File", null, .ImGuiWindowFlags_AlwaysAutoResize);
    {
        if ImGui.Button("Save") {
            save_level(level.*, level.name);
        }
        ImGui.SameLine();
        if ImGui.Button("Load") {
            load_and_initialize_level(level, player, level.name);
        }
        ImGui.SameLine();
        if ImGui.Button("New") {
            save_level(level.*, "new");
            load_and_initialize_level(level, player, "new");
        }
        ImGui.SameLine();
        if ImGui.Button("Wipe") {
            wipe(level);
        }

        ImGui.Text("Current Level: %", level.name);
        ImGui.SameLine();
        if ImGui.InputText("#### Goto", goto_buffer.data, goto_buffer.count, flags=.EnterReturnsTrue | .EscapeClearsAll | .AutoSelectAll) {
            load_and_initialize_level(level, player, to_string(goto_buffer.data));
            memset(goto_buffer.data, 0, goto_buffer.count);
        }
    }
    ImGui.End();
}

level_editor :: (level: *Level, player: *Player) {
    ImGui.Begin("Level", null, .ImGuiWindowFlags_AlwaysAutoResize);
    {
        if ImGui.BeginTabBar("Level Tabs")
        {
            if ImGui.BeginTabItem("Tiles") {
                ImGui.SliderInt("### Paint", xx *editor.current_tile_painting_catalogue_index, 1, xx (tile_catalogue.count - 1), temp_c_string(tprint("% - %", editor.current_tile_painting_catalogue_index, tile_catalogue[xx editor.current_tile_painting_catalogue_index].name)));

                ImGui.EndTabItem();
            }

            if ImGui.BeginTabItem("Platforms") {
                if level.platforms.count {
                    if editor.current_platform_index == -1 then editor.current_platform_index = 0;
                    ImGui.SliderInt("### Platform", xx *editor.current_platform_index, 0, xx (level.platforms.count-1));
                }
                if ImGui.Button("New") {
                    platform := array_add(*level.platforms);
                    initialize_platform(platform, width = 32, height = 4, points = .[.{100, 100}, .{140, 100}], speed = 0.1, easing_function_identifier = .IDENTITY);
                    array_add(*simulation.solids, *platform.solid);
                    editor.current_platform_index = level.platforms.count-1;
                }
                if editor.current_platform_index != -1 {
                    ImGui.SameLine();
                    if ImGui.Button("Delete") {
                        array_ordered_remove_by_index(*level.platforms, editor.current_platform_index);
                        editor.current_platform_index -= 1;
                    }

                    ImGui.NewLine();

                    if editor.current_platform_index != -1 {
                        platform_editor(level);
                    }
                }

                ImGui.EndTabItem();
            }

            ImGui.EndTabBar();
        }
    }
    ImGui.End();
}

platform_editor :: (level: *Level) {
    platform := *level.platforms[editor.current_platform_index];
    assert(platform != null);

    edited: bool = false;

    edited |= ImGui.SliderInt("### A.x", cast(*s32)*platform.points[0].x, 0, PIXEL_WIDTH, temp_c_string(tprint("A.x: %", platform.points[0].x)));
    edited |= ImGui.SliderInt("### A.y", cast(*s32)*platform.points[0].y, 0, PIXEL_HEIGHT, temp_c_string(tprint("A.y: %", platform.points[0].y)));

    edited |= ImGui.SliderInt("### B", xx *platform.points[1].x, 0, xx PIXEL_WIDTH, temp_c_string(tprint("B.x: %", platform.points[1].x)));
    edited |= ImGui.SliderInt("### B.y", xx *platform.points[1].y, 0, xx PIXEL_HEIGHT, temp_c_string(tprint("B.y: %", platform.points[1].y)));

    edited |= ImGui.SliderFloat("### Speed", xx *platform.speed, 0.0, xx 1.0, temp_c_string(tprint("Speed: %", platform.speed)));

    ti := type_info(Easing_Function_Identifier);
    easing_function_edited : bool;
    easing_function_edited |= ImGui.SliderInt("### Easing Function", xx *platform.easing_function_identifier, 0, xx (ti.names.count - 1),
        temp_c_string(tprint("%", ti.names[platform.easing_function_identifier])));

    if easing_function_edited then platform.easing_function = lookup_easing_function(platform.easing_function_identifier);
    edited |= easing_function_edited;

    if edited {
        reset_platform(platform);
    }
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

