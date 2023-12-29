// Hal
// Hazard
// Alex Hartford
// December 2023

Hazard :: struct {
    collider : Collider;
}

get_overlapped_hazards :: (collider: Collider, hazards: [..] *Hazard) -> [] *Hazard {
    result : [..] *Hazard;
    result.allocator = temp;

    for hazard : hazards {
        if collision(collider, hazard.collider) {
            array_add(*result, hazard);
        }
    }

    return result;
}
