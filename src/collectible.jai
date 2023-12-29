// Hal
// Collectible
// Alex Hartford
// December 2023

Collectible :: struct {
    collider : Collider;
    kind : Collectible_Kind;

    collected: bool;
}

Collectible_Kind :: enum {
    NONE;
    COIN;
    GEM;
}

get_overlapped_collectibles :: (collider: Collider, collectibles: [..] *Collectible) -> [] *Collectible {
    result : [..] *Collectible;
    result.allocator = temp;

    for collectible : collectibles {
        if collision(collider, collectible.collider) {
            array_add(*result, collectible);
        }
    }

    return result;
}
