// Hal
// Animation
// Alex Hartford
// October 2023

Animation :: struct {
    name : string;
    value : *int;

    // Properties
    duration : float;

    Keyframe :: struct {
        time : float;
        value : int;
    }
    keyframes : [..] Keyframe;

    // State
    time : float;
}

animation_make :: (name: string, value: *int, duration: float, keyframes: ..Animation.Keyframe) -> Animation {
    animation: Animation;

    animation.name  = name;
    animation.value = value;
    animation.duration = duration;
    for keyframes {
        array_add(*animation.keyframes, it);
    }

    return animation;
}


update :: (animation: *Animation, dt: float) {
    animation.time += dt;
    if animation.time > animation.duration
        animation.time = animation.time - animation.duration;

    animation.value.* = get_value(animation.*);
}

start :: (animation: *Animation) {
    animation.time = 0.0;
    animation.value.* = get_value(animation.*); 
}

//

get_value :: (animation: Animation) -> int {
    if !animation.keyframes {
        log_error("No keyframes!\n");
        return 0;
    }

    for animation.keyframes {
        if it.time > animation.time then return animation.keyframes[it_index-1].value;
    }

    return animation.keyframes[animation.keyframes.count-1].value;
}
