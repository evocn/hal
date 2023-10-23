// Hal
// Anim
// Alex Hartford
// October 2023

Anim :: struct {
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

update :: (anim: *Anim, dt: float) {
    // Update time.
    anim.time += dt;
    if anim.time > anim.duration
        anim.time = anim.time - anim.duration;


    // Update value.
    anim.value.* = get_value(anim.*);
}

begin :: (anim: *Anim) {
    anim.time = 0.0;
    anim.value.* = get_value(anim.*); 
}

//

get_value :: (anim: Anim) -> int {
    if !anim.keyframes {
        log_error("No keyframes!\n");
        return 0;
    }

    for anim.keyframes {
        if it.time > anim.time then return anim.keyframes[it_index-1].value;
    }

    return anim.keyframes[anim.keyframes.count-1].value;
}
