// Hal
// Air Stream
// Alex Hartford
// October 2023

// Specialty Gameplay feature for putting wind in the game.

DEFAULT_WIND_STREAM_STRENGTH :: 1.0;

Wind_Stream :: struct {
    direction : Direction = Right;
    row_or_column_based_on_direction : int;

    strength := DEFAULT_WIND_STREAM_STRENGTH;
}


guy_in_wind_stream :: (guy: Guy, stream: Wind_Stream) -> bool {
    low_threshold := cast(float)stream.row_or_column_based_on_direction * TILE_SIZE_IN_PIXELS;
    high_threshold := low_threshold + TILE_SIZE_IN_PIXELS;

    if stream.direction == Up
        return guy.position.x >= low_threshold && guy.position.x < high_threshold;
    else
        return guy.position.y >= low_threshold && guy.position.y < high_threshold;
}

get_velocity_generated_from_wind_streams :: (guy: Guy, streams: [] Wind_Stream) -> Vector2 {
    result : Vector2;

    for streams {
        if it.direction == Right {
            if guy_in_wind_stream(guy, it)
                result += .{it.strength, 0};
        }
        else if it.direction == Left {
            if guy_in_wind_stream(guy, it)
                result += .{-it.strength, 0};
        }
        else if it.direction == Up {
            if guy_in_wind_stream(guy, it)
                result += .{0, it.strength};
        }
        else {
            log_error("Non-cardinal direction for a wind stream!\n");
        }
    }

    return result * 10;
}
