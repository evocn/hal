// Umi
// Color
// Alex Hartford
// July 2023

Color :: Vector4;
Hex_Color :: u32;

// Byrne 5 Palette
black_hex   : Hex_Color : 0x060608;
white_hex   : Hex_Color : 0xffffff;
gray_hex    : Hex_Color : 0x7c7c7c;

color_1_hex : Hex_Color : 0x2f256b; // Purple
color_2_hex : Hex_Color : 0xf42e1f; // Red
color_3_hex : Hex_Color : 0x67ab7a; // Green
color_4_hex : Hex_Color : 0xECA72C; // Yellow

color_from_hex :: ($h: u32) -> Color {
    color : Color;
    color.x = ((h >> 16) & 0xff) / 255.0;
    color.y = ((h >> 8) & 0xff) / 255.0;
    color.z = ((h >> 0) & 0xff) / 255.0;
    color.w = 1.0;

    return color;
}

//
//

color_none :: Color.{};
white :: #run color_from_hex(white_hex);
black :: #run color_from_hex(black_hex);
gray :: #run color_from_hex(gray_hex);

color_1  :: #run color_from_hex(color_1_hex);
color_2  :: #run color_from_hex(color_2_hex);
color_3  :: #run color_from_hex(color_3_hex);
color_4  :: #run color_from_hex(color_4_hex);

//
//

rainbow_color : Color;

rainbow_color_time : float;
RAINBOW_OSCILLATION_SPEED :: 4.0;

update_rainbow_color :: (dt: float) -> Color {
    rainbow_color_time += dt * RAINBOW_OSCILLATION_SPEED;

    if rainbow_color_time >= 4.0 then rainbow_color_time = rainbow_color_time - 4.0;
    
    if rainbow_color_time > 3.0 then return color_4;
    else if rainbow_color_time > 2.0 then return color_3;
    else if rainbow_color_time > 1.0 then return color_2;
    return color_1;
}

//
//

get_health_bar_color :: (percent : float) -> Color {
    if percent > 0.66 then return color_3;
    else if percent > 0.33 then return color_4;
    return color_2;
}
