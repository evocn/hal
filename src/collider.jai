// Hal
// Collider
// Alex Hartford
// December 2023


// All colliders are axis-aligned bounding boxes (AABBs)
// All collider positions, widths, and heights are integer numbers
// Except for special circumstances, Actors and Solids will never overlap
// Solids do not interact with other Solids


Collider :: struct {
    x, y : int;
    width, height : int;
}

collision :: (a: Collider, b: Collider) -> bool {
    return a.x < b.x + b.width && a.y < b.y + b.height
        && a.x + a.width > b.x && a.y + a.height > b.y;
}

draw :: (collider: Collider, color := white) {
    draw_colored_rectangle(xx collider.x, xx collider.y, xx collider.width, xx collider.height, color=color);
}


//
//

clamp_player_to_level_boundary :: (player : *Player, level_width : int, level_height : int) {
    player.actor.collider.x = clamp(player.actor.collider.x, 0, level_width - player.actor.collider.width);
}

check_collision_against_all_solids :: (collider : Collider, solids : [] *Solid) -> bool {
    for solids {
        if collision(collider, it.collider) return true;
    }

    return false;
}

check_if_hitting_head :: (actor : Actor) -> bool {
    extended_collider := actor.collider;
    extended_collider.y += 1;

    relevant_solids := filter_irrelevant_solids(simulation.solids, actor);

    for solid : relevant_solids {
        if collision(extended_collider, solid.collider) return true;
    }
    
    return false;
}

check_if_grounded :: (actor : Actor) -> bool {
    extended_collider := actor.collider;
    extended_collider.y -= 1;

    relevant_solids := filter_irrelevant_solids(simulation.solids, actor);

    for solid : relevant_solids {
        if collision(extended_collider, solid.collider) {
            return true;
        }
    }
    
    return false;
}
