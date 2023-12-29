// Hal
// Animation Machine
// Alex Hartford
// December 2023

Animation_Machine :: struct {
    frame : int;
    orientation := Right;

    animations : [..] Animation;
}

update :: (animation_machine: *Animation_Machine, dt: float) {
    for * animation_machine.animations {
        update(it, dt);
    }
}

destroy :: (animation_machine: *Animation_Machine) {
    for * animation_machine.animations {
        array_reset(*it.keyframes);
    }
}
