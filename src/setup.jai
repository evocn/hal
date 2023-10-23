// Hal
// Init
// Alex Hartford
// June 2023

VERSION :: 1;

DEBUG_MEMORY :: true;

//

/*
WINDOW_WIDTH  :: 1536;
WINDOW_HEIGHT :: 864;

PIXEL_WIDTH :: 256;
PIXEL_HEIGHT :: 144;
*/

WINDOW_WIDTH  :: 1024;
WINDOW_HEIGHT :: 1152;

PIXEL_WIDTH :: 256;
PIXEL_HEIGHT :: 288;

VIEWPORT_WIDTH := 16;
VIEWPORT_HEIGHT := 18;

TILE_SIZE :: 16;

//

forever_pool: Flat_Pool;

window          : *SDL_Window;
gl_context      : *SDL_GLContext;
imgui_context   : *ImGui.ImGuiContext;

rendering : struct {
    using shaders : struct {
        basic_shader    : Shader;
        tile_shader     : Shader;
        text_shader     : Shader;
        quad_shader     : Shader;
        sprite_shader   : Shader;
    }

    quad : Quad;

    spritesheet : Spritesheet;
}
main_font : Font;
body_font : Font;

menu : Menu;

//

window_width  : s32 = WINDOW_WIDTH;
window_height : s32 = WINDOW_HEIGHT;

fullscreen : bool;

//

running := true;
current_level : string;

//
//
//

assets_path     :: "assets";
fonts_path      :: "assets/fonts";
music_path      :: "assets/audio/music";
ambience_path   :: "assets/audio/ambiences";
sfx_path        :: "assets/audio/sfx";

boards_path     :: "boards";
tweaks_path     :: ".";

//
// Setup Function //////////////////////////////////////////////////////////////
//

setup :: () {
    set_working_directory_to_base_folder();

    set_print_style_in_context();

    init_sdl();
    init_gl();
    init_imgui();

    init_rendering_structures();

    init_images();

    init_fonts();

    init_audio();

    init_input();

    apply_default_settings();
    tweaks_file_exists := load_tweaks_file_and_apply_results("all");
    if !tweaks_file_exists then log("No tweaks file found. Sticking to the defaults!\n");

    init_menus();
}

//
// Subsystem Initialization ////////////////////////////////////////////////////
//

init_sdl :: () {
    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK);

    window = SDL_CreateWindow("Hal",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, window_width, window_height,
        SDL_WINDOW_OPENGL|SDL_WINDOW_SHOWN);

    if !window {
        print("Could not create window: %\n", to_string(SDL_GetError()));
        assert(false);
    }
    SDL_SetWindowResizable(window, xx false);

    // Settings
    SDL_ShowCursor(0);
    SDL_SetRelativeMouseMode(SDL_TRUE);

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);
}

init_gl :: () {
    gl_context = SDL_GL_CreateContext(window);
    if !gl_context {
        print( "Could not create OpenGL context: %\n", to_string(SDL_GetError()));
        assert(false);
    }  

    gl_load(*gl, SDL_GL_GetProcAddress);
    //print("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
    //print("GL Version = %\n", to_string(glGetString(GL_VERSION)));

    // Settings
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);  
    // Note that this is not a complete solution. In order to properly do alpha blending...
    // 1. Draw all the opaque objects.
    // 2. Sort all the transparent objects by distance to the viewer.
    // 3. Draw all the transparent object in sorted order.

}

init_imgui :: () {
    imgui_context = ImGui.CreateContext();
    ImGui_ImplSdl_Init(window);

    ImGui.StyleColorsClassic();
    //ImGui.StyleColorsLight();
}


init_audio :: () {
    audio_context = New(Audio_Context);

    result := ma_engine_init(null, *audio_context.engine);
    if result != .MA_SUCCESS {
        log_error("Unable to initialize the miniaudio engine!\n");
        assert(false);
    }

    {
        // Sound Groups
        result = ma_sound_group_init(*audio_context.engine, 0, null, *audio_context.music_group);
        if result != .MA_SUCCESS {
            log_error("Unable to initialize one or more sound groups.\n");
            assert(false);
        }

        result = ma_sound_group_init(*audio_context.engine, 0, null, *audio_context.sfx_group);
        if result != .MA_SUCCESS {
            log_error("Unable to initialize one or more sound groups.\n");
            assert(false);
        }

        result = ma_sound_group_init(*audio_context.engine, 0, null, *audio_context.ambience_group);
        if result != .MA_SUCCESS {
            log_error("Unable to initialize one or more sound groups.\n");
            assert(false);
        }
    }

    {
        // SFX
        sfx_paths := File_Utilities.file_list(sfx_path, recursive = true, follow_symlinks = false);
        for sfx_paths {
            load_sfx(it);
            free(it.data);
        }

        array_reset(*sfx_paths);
    }

    {
        // Music
        music_paths := File_Utilities.file_list(music_path, recursive = true, follow_symlinks = false);
        for music_paths {
            load_music(it);
            free(it.data);
        }

        array_reset(*music_paths);
    }

    {
        // Ambiences
        ambience_paths := File_Utilities.file_list(ambience_path, recursive = true, follow_symlinks = false);
        for ambience_paths {
            load_ambience(it);
            free(it.data);
        }

        array_reset(*ambience_paths);
    }
}

init_fonts :: () {
    initialize_freetype();

    initialize_font(*main_font, "bm/bm.ttf", 9);
    initialize_font(*body_font, "gosub/gosub.otf", 7);

    FT_Done_FreeType(ft);
}

init_rendering_structures :: () {
    using rendering;

    // Shaders
    basic_shader = make_shader("screen.vs", "basic.fs");
    tile_shader  = make_shader("screen.vs", "texture.fs");
    text_shader  = make_shader("text.vs", "text.fs");
    quad_shader  = make_shader("quad.vs", "quad.fs");
    sprite_shader= make_shader("sprite.vs", "texture.fs");

    // Primitives
    init_quad_rendering_objects(*quad);

    // Buffers
    init_framebuffer();
}

init_images :: () {
    success : bool;

    // Spritesheets
    full_path := tprint("%/sheet.png", assets_path);
    success = make_spritesheet(*rendering.spritesheet, full_path, TILE_SIZE);
    assert(success);
}

init_menus :: () {
    a: Allocator;
    a.proc = flat_pool_allocator_proc;
    a.data = *forever_pool;

    {
        using menu;
        elements.allocator = a;
        name = "Pause";

        resume := New(Go_Element, allocator=a);
        resume.name = "Resume";
        resume.callback = resume_game;
        array_add(*elements, cast(*Menu_Element)resume);

        screen_mode := New(Checkbox_Element, allocator=a);
        screen_mode.name = "Fullscreen";
        screen_mode.callback = set_screen_mode_according_to_fullscreen_variable;
        screen_mode.value = *fullscreen;
        array_add(*elements, cast(*Menu_Element)screen_mode);

        sfx := New(Slider_Element, allocator=a);
        sfx.name = "Sounds";
        sfx.value = ma_sound_group_get_volume(*audio_context.sfx_group);
        sfx.callback = set_sfx_volume;
        array_add(*elements, cast(*Menu_Element)sfx);

        music := New(Slider_Element, allocator=a);
        music.name = "Music";
        music.value = ma_sound_group_get_volume(*audio_context.music_group);
        music.callback = set_music_volume;
        array_add(*elements, cast(*Menu_Element)music);

        ambience := New(Slider_Element, allocator=a);
        ambience.name = "Ambience";
        ambience.value = ma_sound_group_get_volume(*audio_context.ambience_group);
        ambience.callback = set_ambience_volume;
        array_add(*elements, cast(*Menu_Element)ambience);

        quit := New(Go_Element, allocator=a);
        quit.name = "Quit";
        quit.callback = quit_game;
        array_add(*elements, cast(*Menu_Element)quit);
    }
}

// For now, we're just gonna let the gamepad double keyboard inputs. Don't worry about it.
// Later, we'll switch what is active based on if a gamepad is plugged in or not. Maybe.
// Maybe we'll just forget this ever happened.
init_input :: () {
    // Init Gamepad
    if SDL_NumJoysticks() > 0 {
        gamepad = SDL_JoystickOpen(0);
        assert(gamepad != null);
    }
}

//
// Various Configuration Functions /////////////////////////////////////////////
//

set_working_directory_to_base_folder :: () {
	executable_path := path_strip_filename(System.get_path_of_running_executable());
	set_working_directory(tprint("%/../", executable_path));
}

set_print_style_in_context :: () {
    context.print_style.default_format_float = FormatFloat.{trailing_width=2};
}

deactivate_mouse :: () {
    SDL_ShowCursor(0);
    SDL_SetRelativeMouseMode(SDL_TRUE);
}

activate_mouse :: () {
    SDL_ShowCursor(1);
    SDL_SetRelativeMouseMode(SDL_FALSE);
    SDL_WarpMouseInWindow(window, window_width / 2, window_height / 2);
}

//
// Shutdown ////////////////////////////////////////////////////////////////////
//

// Note that this function doesn't actually need to exist. The OS will always clean our stuff up.
// This is just here so we can clean house and see the real leaks if they happen when we are debugging memory.
cleanup_for_shutdown :: () {
    array_reset(*menu.elements);

    free(current_level.data);

    // Audio Cleanup
    {
        using audio_context;

        for sfx {
            free(it_index.data);
            ma_sound_uninit(it);
        }
        deinit(*sfx);

        for music {
            free(it_index.data);
            ma_sound_uninit(it);
        }
        deinit(*music);

        for ambience {
            free(it_index.data);
            ma_sound_uninit(it);
        }
        deinit(*ambience);
        
        ma_engine_uninit(*engine);

        free(audio_context);
    }

    array_reset(*menu.elements);
    deinit(*main_font.characters);
    deinit(*body_font.characters);
    reset(*forever_pool, overwrite_memory=true);

    ImGui_ImplSdl_Shutdown();
    ImGui.DestroyContext(imgui_context);
    SDL_GL_DeleteContext(gl_context);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

