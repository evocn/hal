// Hal
// Main
// Alex Hartford
// September 2023

simulation_rate := 1;
frame_counter := 0;

debug : bool;

pool: Flat_Pool;

main :: () {
    setup_everything();

    guy : Guy;
    {
        guy.idle_anim = Anim.{value=*guy.frame, duration=1.0};
        array_add(*guy.idle_anim.keyframes, .{0.0, 32});
        array_add(*guy.idle_anim.keyframes, .{0.5, 33});

        guy.walk_anim = Anim.{value=*guy.frame, duration=1.0};
        array_add(*guy.walk_anim.keyframes, .{0.0,  36});
        array_add(*guy.walk_anim.keyframes, .{0.25, 37});
        array_add(*guy.walk_anim.keyframes, .{0.5,  38});
        array_add(*guy.walk_anim.keyframes, .{0.75, 39});

        guy.collision_box = Rect.{size=.{GUY_COLLISION_BOX_WIDTH, GUY_COLLISION_BOX_HEIGHT}};
    }

    level: Level;

    load_and_initialize_level(*level, *guy, "1");

    //

    dt, last_frame := 0.0;
    while running {
        // Input & Simulate
        if frame_counter % simulation_rate == 0 {
            frame_cleanup();

            handle_input();

            simulate(*guy, *level, dt);
            rainbow_color = update_rainbow_color(dt);
        }

        { // Render & Editor
            render_plus_editor(*guy, *level);
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

    array_reset(*level.columns);
    array_reset(*level.wind_streams);
    array_reset(*guy.walk_anim.keyframes);
    array_reset(*guy.idle_anim.keyframes);

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

#load "scene.jai";

#load "pair.jai";
#load "anim.jai";

// Rendering
#load "primitives.jai";
#load "shader.jai";
#load "texture.jai";
#load "sprite.jai";
#load "spritesheet.jai";
#load "framebuffer.jai";
#load "color.jai";

// Subsystems
#load "font.jai";
#load "audio.jai";
#load "menu.jai";
#load "tweaks.jai";
#load "dprint.jai";

#load "imgui_init.jai";
#load "editor.jai";

#load "physics.jai";
#load "storage.jai";

// Gameplay Files
#load "player.jai";
#load "level.jai";
#load "tiles.jai";
#load "windstream.jai";
