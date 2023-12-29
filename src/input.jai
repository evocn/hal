// Umi
// Input
// Alex Hartford
// June 2023

reset_input :: (input: *Input) {
    input.just_pressed = 0;
    input.held = 0;
}

Buttons :: enum_flags u8 {
    UP;
    LEFT;
    DOWN;
    RIGHT;
    A;
    B;
    START;
    SELECT;
}

Input :: struct {
    just_pressed : Buttons;
    held : Buttons;
}

button_was_just_pressed :: (input: Input, b: Buttons) -> bool {
    return xx (b & input.just_pressed);
}

button_is_held :: (input: Input, b: Buttons) -> bool {
    return xx (b & input.held);
}

gamepad : *SDL_Joystick;
JOYSTICK_DEAD_ZONE :: 8000;

//
//
//

handle_input :: (input: *Input) {
    // Reset pressed buttons
    {
        input.just_pressed = 0;
    }

    event : SDL_Event;
    while SDL_PollEvent(*event) {
        ImGui_ImplSdl_ProcessEvent(*event);
        if event.type == {
            case SDL_QUIT;
                running = false;
            case SDL_KEYUP;
                if program_state.imgui_capturing_keyboard return;

                // Main Program Inputs
                {
                    if event.key.keysym.sym == SDLK_w {
                        input.held ^= .UP;
                    }
                    if event.key.keysym.sym == SDLK_a {
                        input.held ^= .LEFT;
                    }
                    if event.key.keysym.sym == SDLK_s {
                        input.held ^= .DOWN;
                    }
                    if event.key.keysym.sym == SDLK_d {
                        input.held ^= .RIGHT;
                    }

                    if event.key.keysym.sym == SDLK_SPACE {
                        input.held ^= .A;
                    }
                    if event.key.keysym.sym == SDLK_LSHIFT {
                        input.held ^= .B;
                    }

                    if event.key.keysym.sym == SDLK_ESCAPE {
                        input.held ^= .START;
                    }
                    if event.key.keysym.sym == SDLK_RETURN {
                        input.held ^= .SELECT;
                    }
                }

            case SDL_KEYDOWN;
                if program_state.imgui_capturing_keyboard return;

                // Main Program Inputs
                {
                    if event.key.repeat != 0 return;

                    if event.key.keysym.sym == SDLK_w {
                        input.just_pressed |= .UP;
                        input.held |= .UP;
                    }
                    if event.key.keysym.sym == SDLK_a {
                        input.just_pressed |= .LEFT;
                        input.held |= .LEFT;
                    }
                    if event.key.keysym.sym == SDLK_s {
                        input.just_pressed |= .DOWN;
                        input.held |= .DOWN;
                    }
                    if event.key.keysym.sym == SDLK_d {
                        input.just_pressed |= .RIGHT;
                        input.held |= .RIGHT;
                    }

                    if event.key.keysym.sym == SDLK_SPACE {
                        input.just_pressed |= .A;
                        input.held |= .A;
                    }
                    if event.key.keysym.sym == SDLK_LSHIFT {
                        input.just_pressed |= .B;
                        input.held |= .B;
                    }

                    if event.key.keysym.sym == SDLK_ESCAPE {
                        input.just_pressed |= .START;
                        input.held |= .START;
                    }
                    if event.key.keysym.sym == SDLK_RETURN {
                        input.just_pressed |= .SELECT;
                        input.held |= .SELECT;
                    }
                }

                // Development keybinds
                {
                    // Editor
                    if event.key.keysym.sym == SDLK_r {
                        if current_scene == {
                            case .GAME;
                            switch_scene(.EDITOR);
                            reset_editor_state();
                            //activate_mouse();

                            case .EDITOR;
                            switch_scene(.GAME);
                            //deactivate_mouse();
                        }
                    }

                    // Debug Display
                    if event.key.keysym.sym == SDLK_BACKQUOTE {
                        debug = !debug;
                    }

                    // Simulation Rate
                    if current_scene == .GAME {
                        if event.key.keysym.sym == SDLK_0 {
                            simulation_rate = 50; frame_counter = 0;
                            dprint_once(sprint("Rate: %", cast(float)1 / simulation_rate));
                        }
                        if event.key.keysym.sym == SDLK_1 {
                            simulation_rate = 1; frame_counter = 0;
                            dprint_once(sprint("Rate: %", cast(float)1 / simulation_rate));
                        }
                        if event.key.keysym.sym == SDLK_2 {
                            simulation_rate = 2;
                            dprint_once(sprint("Rate: %", cast(float)1 / simulation_rate));
                        }
                        if event.key.keysym.sym == SDLK_3 {
                            simulation_rate = 10;
                            dprint_once(sprint("Rate: %", cast(float)1 / simulation_rate));
                        }
                    }
                }


                // @SHIP: Fix this! Too fast!
            /*
            case SDL_JOYAXISMOTION;
                if event.jaxis.which == 0 {
                    if event.jaxis.axis == 0 {
                        if event.jaxis.value < -JOYSTICK_DEAD_ZONE
                            input.left  = true;
                        else if event.jaxis.value > JOYSTICK_DEAD_ZONE
                            input.right = true;
                        else {
                            input.left  = false;
                            input.right = false;
                        }
                    }
                    else if event.jaxis.axis == 1 {
                        if event.jaxis.value < -JOYSTICK_DEAD_ZONE
                            input.up    = true;
                        else if event.jaxis.value > JOYSTICK_DEAD_ZONE
                            input.down  = true;
                        else {
                            input.up    = false;
                            input.down  = false;
                        }
                    }
                }
            */

            case SDL_JOYBUTTONDOWN;
                // 0, 1, 2, 3 : face buttons
                // 4, 5 : left bumper / right bumper
                // 6, 7 : select / start
                // 8, 9 : pressing in left stick / right stick

                if event.jbutton.button == 0 {
                    input.just_pressed |= .A;
                    input.held |= .A;
                }
                if event.jbutton.button == 1 {
                    input.just_pressed |= .B;
                    input.held |= .B;
                }
                if event.jbutton.button == 6 {
                    input.just_pressed |= .START;
                    input.held |= .START;
                }
                if event.jbutton.button == 7 {
                    input.just_pressed |= .SELECT;
                    input.held |= .SELECT;
                }

            case SDL_JOYBUTTONUP;
                if event.jbutton.button == 0 {
                    input.held ^= .A;
                }
                if event.jbutton.button == 1 {
                    input.held ^= .B;
                }
                if event.jbutton.button == 6 {
                    input.held ^= .START;
                }
                if event.jbutton.button == 7 {
                    input.held ^= .SELECT;
                }

            case SDL_JOYHATMOTION;
                hat_state : u8;
                hat_state = event.jhat.value;

                // @TODO!

                if hat_state & 1 {
                    // up
                }
                if hat_state & 2 {
                    // right
                }
                if hat_state & 4 {
                    // down
                }
                if hat_state & 8 {
                    // left
                }

            case SDL_JOYDEVICEADDED;
                gamepad = SDL_JoystickOpen(0);
                assert(gamepad != null);

            case SDL_JOYDEVICEREMOVED;
                gamepad = null;

            case SDL_WINDOWEVENT;
                if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED {
                    window_height = event.window.data2;
                    window_width = event.window.data1;

                    viewport_height = window_height;
                    viewport_width  = cast(s32)(viewport_height * DESIRED_ASPECT_RATIO);
                }
        }
    }
}
