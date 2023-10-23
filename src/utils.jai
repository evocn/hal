// Hal
// Utils
// Alex Hartford
// September 2023

print_gl_errors :: (str := "-") {
    if dont_check_for_gl_errors_anymore then return;

    current_error : GLenum;
    current_error = glGetError();
    while current_error != GL_NO_ERROR {
        dont_check_for_gl_errors_anymore = true;

        log_error("OpenGL Error(%) = %\n", str, current_error);

        current_error = glGetError();
    }
}
dont_check_for_gl_errors_anymore : bool;

////////////////////////////////////////////////////////////////////////////////
// Parsing
//

parse_int_pair :: (handler: *Text_File_Handler) -> Pixel, success: bool {
    result : Pixel;
    line, found := consume_next_line(handler);
    if !found return result, false;

    success : bool;
    remainder : string;
    result.x, success, remainder = string_to_int(line);
    result.y, success, remainder = string_to_int(remainder);

    return result, true;
}
