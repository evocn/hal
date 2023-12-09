// Hal
// Render
// Alex Hartford
// September 2023

render_plus_editor :: (guy: *Guy, level: *Level) {
    render(guy.*, level.*);

    // Draw extra things on top of the framebuffer.
    if current_scene == .EDITOR {
        update_and_draw_editor(level, guy);
        ImGui_ImplSdl_RenderDrawLists(ImGui.GetDrawData());
    }

    SDL_GL_SwapWindow(window);
}

render :: (guy: Guy, level: Level) {
    {
        // Render all this to the framebuffer.
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);
        glViewport(0, 0, PIXEL_WIDTH, PIXEL_HEIGHT);
        glClearColor(black.x, black.y, black.z, 1);
        glClear(GL_COLOR_BUFFER_BIT);

        if #complete current_scene == {
            case .GAME;
                draw_game_state(guy, level);
                draw_user_interface(guy, level);
                if debug {
                    draw_debug_info();
                }

                draw_debug_messages();

            case .EDITOR;
                draw_game_state(guy, level);
                draw_user_interface(guy, level);
                if debug {
                    draw_debug_info();
                }

                draw_debug_messages();

                draw_editor_interface(level);

            case .MENU;
                render_menu(menu);
                draw_controls();
        }
    }

    render_framebuffer_to_screen();
}

draw_game_state :: (guy: Guy, level: Level) {
    for tiles, col: level.columns {
        for tile, row: tiles {
            draw_tile(tile.background, .{col, row} * TILE_SIZE_IN_PIXELS, color=tile.color);
        }
    }

    for level.wind_streams {
        draw_wind_stream(it, level, color=gray);
    }

    if debug {
        tiles := gather_all_tiles_with_collision_boxes(level);
        for tile: tiles {
            collision_box_color := gray;
            if (tile.properties & .KILL) {
                collision_box_color = color_2;
            }
            draw(tile.collision_box, collision_box_color);
        }
        draw(guy.collision_box, gray);
    }

    draw_level_start(level.start);
    draw_level_end(level.end);

    draw_guy(guy);
}

draw_guy :: (guy: Guy) {
    draw_tile(guy.frame, convert_to_pixel(guy.position), color = color_4, horizontal_flip = (guy.orientation == Left));
}

draw_level_start :: (tile_index: Tile_Index) {
    draw_tile(18, tile_index * TILE_SIZE_IN_PIXELS, color=gray);
}

draw_level_end :: (tile_index: Tile_Index) {
    draw_tile(17, tile_index * TILE_SIZE_IN_PIXELS, color=color_1);
}

//

draw_wind_stream_tile :: (tile_index : Tile_Index, horizontal_flip : bool, vertical_flip : bool, color : Color) {
    if vertical_flip {
        draw_tile(20, tile_index * TILE_SIZE_IN_PIXELS, color=color, horizontal_flip=horizontal_flip);
    }
    else {
        draw_tile(21, tile_index * TILE_SIZE_IN_PIXELS, color=color, horizontal_flip=horizontal_flip);
    }
}

draw_wind_stream :: (wind_stream: Wind_Stream, level: Level, color := gray) {
    level_width := level.columns[0].count;
    level_height := LEVEL_HEIGHT;
    if wind_stream.direction == Left {
        for 0..level_width-1 {
            draw_wind_stream_tile(.{it, wind_stream.row_or_column_based_on_direction}, true, false, color=color);
        }
    }
    else if wind_stream.direction == Right {
        for 0..level_width-1 {
            draw_wind_stream_tile(.{it, wind_stream.row_or_column_based_on_direction}, false, false, color=color);
        }
    }
    else if wind_stream.direction == Up {
        for 0..level_height-1 {
            draw_wind_stream_tile(.{wind_stream.row_or_column_based_on_direction, it}, false, true, color=color);
        }
    }
    else {
        log_error("What the heck? That's not a cardinal direction!\n");
        assert(false);
    }
}
    
//
// User Interface //////////////////////////////////////////////////////////////
//

draw_user_interface :: (guy: Guy, level: Level) {
    draw_level_indicator(level);
    draw_coin_indicator();
    //draw_menu_notice();
}

draw_level_indicator :: (level: Level) {
    use_text_shader();
    draw_text_right(tprint("Level %", level.shortname), y=PIXEL_HEIGHT - 10, color=gray);
}

draw_coin_indicator :: () {
    draw_tile(30, .{0, PIXEL_HEIGHT - TILE_SIZE_IN_PIXELS}, color=color_4);
    use_text_shader();
    draw_text(tprint("%", player_state.coins), x=12, y=PIXEL_HEIGHT - 12, color=gray);
}

draw_menu_notice :: () {
    use_text_shader();
    draw_text_right("Esc - Menu", y=PIXEL_HEIGHT - 10, color=gray);
}

//
//
//

draw_editor_interface :: (level: Level) {
    draw_tile(22, editor.cursor * TILE_SIZE_IN_PIXELS, color=rainbow_color);

    if editor.current_wind_stream_index != -1 {
        draw_wind_stream(level.wind_streams[editor.current_wind_stream_index], level, color=rainbow_color);
    }
}

//
// Menu ////////////////////////////////////////////////////////////////////////
//

render_menu :: (using menu: Menu) {
    use_text_shader();

    k := 10;

    for elements {
        draw_menu_element(it, PIXEL_HEIGHT - (it_index + 1) * k, color=color_1);
    }

    // Draw selected element over it.
    if elements.count {
        draw_menu_element(elements[element_index], PIXEL_HEIGHT - (element_index + 1) * k, color=rainbow_color);
    }
}

draw_menu_element :: (using element: *Menu_Element, height : int, color := white) {
    if kind == {
        case .GO;
            using cast(*Go_Element)element;
            draw_text(name, 1, height, color=color);

        case .CHECKBOX;
            using cast(*Checkbox_Element)element;
            str := "Off";
            if value.* then str = "On";
            draw_text(tprint("% - %", name, str), 1, height, color=color);

        case .SLIDER;
            using cast(*Slider_Element)element;
            draw_text(tprint("% - %", name, value), 1, height, color=color);
    }
}

draw_controls :: () {
    use_text_shader();
    k := 10;
    base := 2;

    draw_text_right("Shift : Sprint", y=k * 0 + base, color=gray);
    draw_text_right("Space : Jump and Glide", y=k * 1 + base, color=gray);
    draw_text_right("Move with A/D", y=k * 2 + base, color=gray);
    draw_text_right("Controls", y=k * 3 + base, color=color_2);
}

//
// Miscellaneous ///////////////////////////////////////////////////////////////
//

draw_colored_rectangle :: (x: int, y: int, width: int, height: int, color := white) {
    shader := use_basic_shader();

    model := Matrix4_Identity;
    translation_vector := Vector3.{cast(float)x / PIXEL_WIDTH, cast(float)y / PIXEL_HEIGHT, 0.0};
    scale_vector := Vector3.{cast(float)width / PIXEL_WIDTH, cast(float)height / PIXEL_HEIGHT, 1.0};

    translate(*model, translation_vector);
    scale(*model, scale_vector);
    set_mat4(shader, "model", model);

    set_vec4(shader, "color", color);

    draw_quad(rendering.quad);
}

draw_screen_quad :: (shader: Shader) {
    model := Matrix4_Identity;

    viewport_portion_of_the_screen_in_x := cast(float)viewport_height / window_height;
    viewport_portion_of_the_screen_in_y := cast(float)viewport_width / window_width;

    print("% %\n", viewport_portion_of_the_screen_in_x, viewport_portion_of_the_screen_in_y);

    // Scale
    default_scale_x :: 2;
    default_scale_y :: 2;

    scale_x : float = default_scale_x * viewport_portion_of_the_screen_in_x;
    scale_y : float = default_scale_y * viewport_portion_of_the_screen_in_y;
    scale_vector := Vector3.{scale_y, scale_x, 1};

    // Translate
    default_translate_x :: -1;
    default_translate_y :: -1;

    translate_x : float = xx default_translate_x + scale_y / 2;
    translate_y : float = xx default_translate_y;
    translation_vector := Vector3.{translate_x, translate_y, 1};

    translate(*model, translation_vector);
    scale(*model, scale_vector);

    set_mat4(shader, "model", model);

    draw_quad(rendering.quad);
}

// Renders the framebuffer as a texture on a screen-space quad.
render_framebuffer_to_screen :: () {
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glViewport(0, 0, xx window_width, xx window_height);
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    shader := rendering.quad_shader;
    use_shader(shader);
    defer disable_shaders();

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, render_texture);

    draw_screen_quad(shader);
}
