#version 330 core
out vec4 FragColor;

in vec2 texture_coordinates;

uniform sampler2D render_texture;

void main(){
    FragColor = texture(render_texture, texture_coordinates);
}
