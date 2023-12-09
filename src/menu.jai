// Umi
// Menu
// Alex Hartford
// July 2023

Go_Element :: struct {
    using #as menu_element: Menu_Element;
    kind = .GO;

    callback : #type ();
}

Checkbox_Element :: struct {
    using #as menu_element: Menu_Element;
    kind = .CHECKBOX;

    value : *bool;

    callback : #type ();
}

Slider_Element :: struct {
    using #as menu_element: Menu_Element;
    kind = .SLIDER;

    value : float;
    callback : (float) -> ();

    increment : float = 0.25;
    min : float = 0.0;
    max : float = 1.0;
}

Menu_Element :: struct {
    kind : enum #complete {
        GO;
        CHECKBOX;
        SLIDER;
    }

    name : string;
}

Menu :: struct {
    name : string;

    elements : [..] *Menu_Element;
    element_index : int;
}

resolve_menu_inputs :: (using menu: *Menu) {
    using input;

    if button_was_just_pressed(.START) || button_was_just_pressed(.B) {
        return_to_prior_scene();
        play_sfx("click");
    }

    if button_was_just_pressed(.UP) {
        element_index -= 1;
        if element_index < 0 {
            element_index += 1;
        }
        play_sfx("click");
    }
    if button_was_just_pressed(.DOWN) {
        element_index += 1;
        if element_index >= elements.count {
            element_index -= 1;
        }
        play_sfx("click");
    }
    if button_was_just_pressed(.LEFT) {
        nudge_menu_element(elements[element_index], left=true);
        play_sfx("click");
    }
    if button_was_just_pressed(.RIGHT) {
        nudge_menu_element(elements[element_index]);
        play_sfx("click");
    }

    if button_was_just_pressed(.A) {
        toggle_menu_element(elements[element_index]);
    }
}

// This could return false if we want there to be menu options that bonk on failure.
// Not sure what that would be useful for, just figured I'd mention it in case it became useful.
toggle_menu_element :: (using element: *Menu_Element) {
    if kind == {
        case .GO;
            using cast(*Go_Element)element;
            callback();
            play_sfx("click");

        case .CHECKBOX;
            using cast(*Checkbox_Element)element;
            value.* = !(value.*);
            callback();
            play_sfx("click");

        case .SLIDER;
            // Don't do anything.
    }

    save_tweaks_file("all");
}


nudge_menu_element :: (using element: *Menu_Element, left := false) {
    if kind == {
        case .GO;
            // Don't do anything.

        case .CHECKBOX;
            using cast(*Checkbox_Element)element;
            value.* = !(value.*);
            callback();
            play_sfx("choose");

        case .SLIDER;
            using cast(*Slider_Element)element;
            if left {
                value = clamp(value - increment, min, max);
                callback(value);
            }
            else {
                value = clamp(value + increment, min, max);
                callback(value);
            }
    }

    save_tweaks_file("all");
}

//
// Callbacks for Menu Elements /////////////////////////////////////////////////
//
resume_game :: () {
    return_to_prior_scene();
}

quit_game :: () {
    running = false;
}

go_to_settings :: () {
    switch_scene(.MENU);
    menu.element_index = 0;
}

// Fullscreen stuff

go_fullscreen :: () {
    old_window_width = window_width;
    old_window_height = window_height;

    display_mode : SDL_DisplayMode;
    SDL_GetDesktopDisplayMode(0, *display_mode);

    SDL_SetWindowResizable(window, SDL_FALSE);
    SDL_SetWindowBordered(window, SDL_FALSE);
    SDL_SetWindowPosition(window, 0, 0);
    SDL_SetWindowSize(window, display_mode.w, display_mode.h);

    SDL_GetWindowDisplayMode(window, *display_mode);
}

go_windowed :: () {
    display_mode : SDL_DisplayMode;
    SDL_GetDesktopDisplayMode(0, *display_mode);

    SDL_SetWindowResizable(window, SDL_TRUE);
    SDL_SetWindowBordered(window, SDL_TRUE);
    SDL_SetWindowSize(window, old_window_width, old_window_height);
    SDL_SetWindowPosition(window, display_mode.w / 2 - old_window_width / 2, display_mode.h / 2 - old_window_height / 2);
    SDL_SetWindowResizable(window, SDL_FALSE);

    SDL_GetWindowDisplayMode(window, *display_mode);
}

set_screen_mode_according_to_fullscreen_variable :: () {
    if fullscreen then go_fullscreen();
    else go_windowed();
}
