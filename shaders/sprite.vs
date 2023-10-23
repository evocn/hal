#version 330 core
layout (location = 0) in vec3 VertexPosition;

uniform mat4 projection;
uniform mat4 model;

uniform int horizontal_flip;

out vec2 texture_coordinates;

void main()
{
    vec2 uv = VertexPosition.xy;
    uv.y = 1.0 - uv.y;

    uv.x = (1 - horizontal_flip) * uv.x + (horizontal_flip) * (1.0 - uv.x);

    texture_coordinates = uv;
    gl_Position = projection * model * vec4(VertexPosition, 1.0);
}
