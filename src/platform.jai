// Hal
// Platform
// Alex Hartford
// December 2023

Platform :: struct {
    using solid: Solid;
    velocity: Vector2;

    points : [2] Pair;
    t: float;
    speed: float;

    easing_function_identifier : Easing_Function_Identifier = .IDENTITY;
    easing_function: (float) -> (float) = easing_identity;
}

initialize_platform :: (platform: *Platform, width: int, height: int, points: [2] Pair, 
                        one_way := true, speed := 1.0,
                        easing_function_identifier : Easing_Function_Identifier
                       )
{
    platform.width = width;
    platform.height = height;
    platform.points[0] = points[0];
    platform.points[1] = points[1];
    platform.x = points[0].x;
    platform.y = points[0].y;
    platform.one_way = one_way;
    platform.speed = speed;

    platform.easing_function_identifier = easing_function_identifier;
    easing_function := lookup_easing_function(easing_function_identifier);
    platform.easing_function = easing_function;
}

reset_platform :: (platform: *Platform) {
    platform.x = platform.points[0].x;
    platform.y = platform.points[0].y;

    platform.solid.x_remainder = 0.0;
    platform.solid.y_remainder = 0.0;

    platform.t = 0.0;
}

update :: (platform: *Platform, dt: float) {
    platform.t += dt * platform.speed;
    platform.t = fmod_cycling(platform.t, 2.0);

    t := platform.t;
    if t > 1 then t = 2 - t;

    goal_position : Vector2;
    goal_position.x = lerp(cast(float)platform.points[0].x, cast(float)platform.points[1].x, platform.easing_function(t));
    goal_position.y = lerp(cast(float)platform.points[0].y, cast(float)platform.points[1].y, platform.easing_function(t));

    movement := goal_position - Vector2.{platform.x + platform.solid.x_remainder, platform.y + platform.solid.y_remainder};

    move(*platform.solid, movement.x, movement.y);
}
