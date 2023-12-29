// Hal
// Draw
// Alex Hartford
// December 2023

Pixel :: struct {
    position: Vector2;
    vao, vbo: GLuint;
}

get_pixel_ready_for_drawing_with_opengl :: (using pixel: *Pixel, pixel_position: Pair) {
    pixel.position.x = cast(float)pixel_position.x / PIXEL_WIDTH;
    pixel.position.y = cast(float)pixel_position.y / PIXEL_HEIGHT;

	glGenVertexArrays(1, *vao);
	glGenBuffers(1, *vbo);

	glBindVertexArray(vao);
	defer glBindVertexArray(0);

	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	defer glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBufferData(GL_ARRAY_BUFFER, 2 * size_of(float), *position, GL_STATIC_DRAW);

	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, cast(*void)0);
	glEnableVertexAttribArray(0);
}

draw_pixel :: (using pixel: Pixel) {
	glBindVertexArray(vao);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);

	glDrawArrays(GL_POINTS, 0, 1);
}

////////////////////////////////////////////////////////////////////////////////

Line :: struct {
    points: [2] Vector2;
    vao, vbo: GLuint;
}

get_line_ready_for_drawing_with_opengl :: (using line: *Line, pixel_position_a: Pair, pixel_position_b: Pair) {
    line.points[0].x = cast(float)pixel_position_a.x / PIXEL_WIDTH;
    line.points[0].y = cast(float)pixel_position_a.y / PIXEL_HEIGHT;

    line.points[1].x = cast(float)pixel_position_b.x / PIXEL_WIDTH;
    line.points[1].y = cast(float)pixel_position_b.y / PIXEL_HEIGHT;

	glGenVertexArrays(1, *vao);
	glGenBuffers(1, *vbo);

	glBindVertexArray(vao);
	defer glBindVertexArray(0);

	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	defer glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBufferData(GL_ARRAY_BUFFER, points.count * 2 * size_of(float), *points[0], GL_STATIC_DRAW);

	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, cast(*void)0);
	glEnableVertexAttribArray(0);
}

draw_line :: (using line: Line) {
	glBindVertexArray(vao);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);

	glDrawArrays(GL_LINES, 0, 2);
}
