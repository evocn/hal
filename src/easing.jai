// Hal
// Easing Functions and utilities
// Alex Hartford
// December 2023

easing_identity :: (t: float) -> float {
    return t;
}

flip :: (t: float) -> float {
    return 1 - t;
}

smooth_start :: (t: float) -> float {
    return t * t * t;
}

smooth_stop :: (t: float) -> float {
    return flip(smooth_start(flip(t)));
}

smooth_start_stop :: (t: float) -> float {
    return lerp(smooth_start(t), smooth_stop(t), t);
}

stair :: (t: float) -> float {
    return cast(float)cast(int)t;
}

////////////////////////////////////////////////////////////////////////////////

Easing_Function_Identifier :: enum {
    IDENTITY;
    FLIP;
    SMOOTH_START;
    SMOOTH_STOP;
    SMOOTH_START_STOP;
    STAIR;
}

lookup_easing_function :: (identifier: Easing_Function_Identifier) -> ((float) -> (float)) {
    if #complete identifier == {
        case .IDENTITY;          return easing_identity;
        case .FLIP;              return flip;
        case .SMOOTH_START;      return smooth_start;
        case .SMOOTH_STOP;       return smooth_stop;
        case .SMOOTH_START_STOP; return smooth_start_stop;
        case .STAIR;             return stair;
    }
}
