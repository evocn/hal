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

purple_hex  : Hex_Color : 0x2f256b;
red_hex     : Hex_Color : 0xf42e1f;
green_hex   : Hex_Color : 0x67ab7a;
yellow_hex  : Hex_Color : 0xECA72C;
blue_hex    : Hex_Color : 0x004bd6;

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
white   :: #run color_from_hex(white_hex);
black   :: #run color_from_hex(black_hex);
gray    :: #run color_from_hex(gray_hex);

purple  :: #run color_from_hex(purple_hex);
red     :: #run color_from_hex(red_hex);
green   :: #run color_from_hex(green_hex);
yellow  :: #run color_from_hex(yellow_hex);
blue    :: #run color_from_hex(blue_hex);

//
//

rainbow_color : Color;

rainbow_color_time : float;
RAINBOW_OSCILLATION_SPEED :: 4.0;

update_rainbow_color :: (dt: float) -> Color {
    rainbow_color_time += dt * RAINBOW_OSCILLATION_SPEED;

    if rainbow_color_time >= 4.0 then rainbow_color_time = rainbow_color_time - 4.0;
    
    if rainbow_color_time > 3.0 then return yellow;
    else if rainbow_color_time > 2.0 then return green;
    else if rainbow_color_time > 1.0 then return red;
    return purple;
}

//
//

get_health_bar_color :: (percent : float) -> Color {
    if percent > 0.66 then return green;
    else if percent > 0.33 then return yellow;
    return red;
}
