// Hal
// Render
// Alex Hartford
// September 2023

render :: (player: Player, level: Level) {
    {
        // Render all this to the framebuffer.
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);
        glViewport(0, 0, PIXEL_WIDTH, PIXEL_HEIGHT);
        glClearColor(black.x, black.y, black.z, 1);
        glClear(GL_COLOR_BUFFER_BIT);

        if #complete current_scene == {
            case .GAME;
                draw_game_state(player, level);

                draw_user_interface(level);

                if debug {
                    draw_debug_info();
                }
                draw_debug_messages();

            case .EDITOR;
                draw_game_state(player, level);
                draw_user_interface(level);
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

draw_game_state :: (player: Player, level: Level) {
    for tile, index : level.tiles {
        col := index % level.width;
        row := index / level.width;
        draw_tile(tile.properties.sprite, .{col, row} * TILE_SIZE_IN_PIXELS, color=tile.color);
    }

    for platform: level.platforms {
        draw(platform.solid.collider);
    }

    draw_level_start(level.start);
    draw_level_end(level.end);

    {
        // NPC Sprites
        for npc: level.npcs {
            draw_tile(npc.sprite, npc.tile * TILE_SIZE_IN_PIXELS, color=npc.color);
        }

        use_text_shader();

        // NPC Speech
        for npc: level.npcs {
            draw_text(
                npc.speech,
                xx ((npc.tile.x + 0.5) * cast(float)TILE_SIZE_IN_PIXELS),
                xx ((npc.tile.y + 1.0) * cast(float)TILE_SIZE_IN_PIXELS),
                color=npc.color,
                alignment = .CENTER,
                progress = cast(int)(npc.speech_progress * npc.speech.count),
            );
        }
    }

    {
        use_tile_shader();
        draw_player(player);
    }
}

draw_player :: (player: Player) {
    draw_tile(
        player.sprite, 
        .{player.x - 4, player.y},
        color = yellow, 
        horizontal_flip = player.orientation == Left
    );
}

draw_level_start :: (tile_position: Pair) {
    draw_tile(18, tile_position * TILE_SIZE_IN_PIXELS, color = gray);
}

draw_level_end :: (tile_position: Pair) {
    draw_tile(17, tile_position * TILE_SIZE_IN_PIXELS, color = purple);
}

//
// User Interface //////////////////////////////////////////////////////////////
//

draw_user_interface :: (level: Level) {
    draw_level_indicator(level);
    draw_coin_indicator();
    //draw_menu_notice();
}

draw_level_indicator :: (level: Level) {
    use_text_shader();
    draw_text(tprint("Level %", level.name), x = PIXEL_WIDTH - 10, y = PIXEL_HEIGHT - 10, color = gray, alignment = .RIGHT);
}

draw_coin_indicator :: () {
    draw_tile(30, .{0, PIXEL_HEIGHT - TILE_SIZE_IN_PIXELS}, color = yellow);
    use_text_shader();
    draw_text(tprint("%", game_state.coins), x = 12, y = PIXEL_HEIGHT - 12, color = gray);
}

draw_menu_notice :: () {
    use_text_shader();
    draw_text("Esc - Menu", x = 0, y = PIXEL_HEIGHT - 10, color = gray, alignment = .RIGHT);
}

//
//
//

draw_editor_interface :: (level: Level) {
    draw_tile(22, editor.cursor * TILE_SIZE_IN_PIXELS, color = rainbow_color);

    shader := use_basic_shader();
        set_mat4(shader, "model", Matrix4_Identity);
        set_vec4(shader, "color", rainbow_color);

    if editor.current_platform_index != -1 {
        platform := level.platforms[editor.current_platform_index];

        line: Line;
        get_line_ready_for_drawing_with_opengl(*line, platform.points[0], platform.points[1]);
        draw_line(line);
    }
}

//
// Menu ////////////////////////////////////////////////////////////////////////
//

render_menu :: (using menu: Menu) {
    use_text_shader();

    k := 10;

    for elements {
        draw_menu_element(it, PIXEL_HEIGHT - (it_index + 1) * k, color = purple);
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

    draw_text("Shift : Sprint",         x = 0, y = k * 0 + base, color = gray, alignment = .RIGHT);
    draw_text("Space : Jump and Glide", x = 0, y = k * 1 + base, color = gray, alignment = .RIGHT);
    draw_text("Move with A/D",          x = 0, y = k * 2 + base, color = gray, alignment = .RIGHT);
    draw_text("Controls",               x = 0, y = k * 3 + base, color = red, alignment = .RIGHT);
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

    // Scale
    default_scale_x :: 2;
    default_scale_y :: 2;

    scale_x : float = default_scale_x * viewport_portion_of_the_screen_in_x;
    scale_y : float = default_scale_y * viewport_portion_of_the_screen_in_y;
    scale_vector := Vector3.{scale_y, scale_x, 1};

    // Translate
    default_translate_x :: -1;
    default_translate_y :: -1;

    translate_x : float = default_translate_x * viewport_portion_of_the_screen_in_y;
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
