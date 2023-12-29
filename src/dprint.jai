// Hal
// dprint
// Alex Hartford
// October 2023

draw_debug_info :: () {
    draw_debug_lines();
}

//

debug_lines : [..] string;

dprint :: (s: string) {
    array_add(*debug_lines, s);
}

draw_debug_lines :: (color := red) {
    use_text_shader();

    for debug_lines {
        draw_text(
            it, 
            x = PIXEL_WIDTH / 2, 
            y = PIXEL_HEIGHT - (10 * (1 + it_index)), 
            color=color, 
            alignment = .CENTER
        );
    }
}

//

DEFAULT_MESSAGE_DISPLAY_TIME :: 500;

Debug_Message :: struct {
    s : string;
    frames := DEFAULT_MESSAGE_DISPLAY_TIME;
}

debug_messages : [..] Debug_Message;

dprint_once :: (s: string, frames := DEFAULT_MESSAGE_DISPLAY_TIME) {
    array_add(*debug_messages, .{s, frames});
}

draw_debug_messages :: (color := gray) {
    use_text_shader();

    for * debug_messages {
        draw_text(
            it.s,
            x = PIXEL_WIDTH / 2,
            y = PIXEL_HEIGHT - (10 * (1 + it_index)),
            color=color,
            alignment = .CENTER
        );

        // Maybe remove it!
        it.frames -= 1;
        if it.frames <= 0 {
            free(it.s.data);
            remove it;
        }
    }
}
