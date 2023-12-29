// Hal
// Main
// Alex Hartford
// September 2023

VERSION :: 1;

DEBUG_MEMORY :: true;

//

VIEWPORT_HEIGHT_IN_TILES :: 18;
VIEWPORT_WIDTH_IN_TILES  :: 16;
DESIRED_ASPECT_RATIO : float : cast(float)VIEWPORT_WIDTH_IN_TILES / VIEWPORT_HEIGHT_IN_TILES;

TILE_SIZE_IN_PIXELS :: 16;

PIXEL_WIDTH :: VIEWPORT_WIDTH_IN_TILES * TILE_SIZE_IN_PIXELS;
PIXEL_HEIGHT :: VIEWPORT_HEIGHT_IN_TILES * TILE_SIZE_IN_PIXELS;

DEFAULT_WINDOW_HEIGHT :: 900;
DEFAULT_WINDOW_WIDTH  : s32 : cast(s32)(DEFAULT_WINDOW_HEIGHT * DESIRED_ASPECT_RATIO);

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

window_height : s32 = DEFAULT_WINDOW_HEIGHT;
window_width  : s32 = DEFAULT_WINDOW_WIDTH;

viewport_height: s32 = DEFAULT_WINDOW_HEIGHT;
viewport_width : s32 = cast(s32)(DEFAULT_WINDOW_HEIGHT * DESIRED_ASPECT_RATIO);

fullscreen : bool;

old_window_width  : s32 = DEFAULT_WINDOW_WIDTH;
old_window_height : s32 = DEFAULT_WINDOW_HEIGHT;

//

running := true;

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
//
//

simulation_rate := 1;
frame_counter := 0;

debug : bool;

pool: Flat_Pool;

//
//
//

main :: () {
    setup_everything();

    player: Player;

        array_add(*player.animation_machine.animations,
            animation_make(
                name = "idle",
                value = *player.sprite,
                duration = 1.0,
                .{0.0, 32},
                .{0.5, 33},
            )
        );

        array_add(*player.animation_machine.animations,
            animation_make(
                name = "walk",
                value = *player.sprite,
                duration = 1.0,
                .{0.0,  36},
                .{0.25, 37},
                .{0.5,  38},
                .{0.75, 39},
            )
        );


    level: Level;

    load_and_initialize_level(*level, *player, level_names[current_level_index]);

    //

    input: Input;

    dt, last_frame := 0.0;
    while running {

        // Input & Simulate
        if frame_counter % simulation_rate == 0 {
            frame_cleanup();

            handle_input(*input);

            update(input, *player, *level, dt);
            rainbow_color = update_rainbow_color(dt);
        }

        { // Render & Editor
            render(player, level);

            // Draw extra things on top of the framebuffer.
            if current_scene == .EDITOR {
                update_and_draw_editor(*player, *level);
                ImGui_ImplSdl_RenderDrawLists(ImGui.GetDrawData());
            }

            SDL_GL_SwapWindow(window);

        }

        { // Timing
            current_time := cast(float32)get_time();
            dt = current_time - last_frame;
            FRAME_DURATION :: 0.0166666;

            if dt < FRAME_DURATION {
                SDL_Delay(xx (1000 * (FRAME_DURATION - dt)));
                dt = FRAME_DURATION;
            }

            last_frame = current_time;
        }

        frame_counter += 1; if frame_counter >= 1000 then frame_counter = 0;
    }

    reset_simulation();
    wipe(*level);

    array_reset(*debug_messages);

    cleanup_for_shutdown();
    #if DEBUG_MEMORY then report_memory_leaks();
}

frame_cleanup :: () {
    reset_temporary_storage();

    for debug_lines free(it.data);
    array_reset(*debug_lines);
}

//
// Imports /////////////////////////////////////////////////////////////////////
//

using Basic :: #import "Basic"()(MEMORY_DEBUGGER=DEBUG_MEMORY);
#import "Flat_Pool";

#import "String";
#import "Math";
#import "Hash_Table";
#import "Bucket_Array";
#import "Random";
#import "Sort";

#import "File";
#import "Text_File_Handler";

File_Utilities :: #import "File_Utilities"; // For file_list()
System         :: #import "System";         // For get_path_of_running_executable()

#import "stb_image";

#import "SDL";
#import "GL";
ImGui :: #import "ImGui";

#import "freetype-2.12.1";
#import "miniaudio";

//
// Loads ///////////////////////////////////////////////////////////////////////
//

// Core
#load "utils.jai";
#load "setup.jai";

#load "input.jai";
#load "simulate.jai";
#load "render.jai";
#load "draw.jai";

#load "scene.jai";

#load "pair.jai";
#load "animation.jai";
#load "animation_machine.jai";

// Rendering
#load "primitives.jai";
#load "shader.jai";
#load "texture.jai";
#load "sprite.jai";
#load "spritesheet.jai";
#load "framebuffer.jai";
#load "color.jai";

#load "easing.jai";

// Subsystems
#load "font.jai";
#load "audio.jai";
#load "menu.jai";
#load "tweaks.jai";
#load "dprint.jai";

#load "imgui_init.jai";
#load "editor.jai";

#load "storage.jai";

// Gameplay Files
#load "game.jai";
#load "player.jai";
#load "collider.jai";
#load "actor.jai";
#load "solid.jai";
#load "level.jai";
#load "tiles.jai";
#load "collectible.jai";
#load "hazard.jai";
#load "platform.jai";

#load "npc.jai";
#load "wind.jai";
