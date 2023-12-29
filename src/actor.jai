// Hal
// Actor
// Alex Hartford
// December 2023

Actor :: struct {
    using collider: Collider;
    x_remainder: float;
    y_remainder: float;

    should_die : bool;
}

// Rounds to the nearest int.
round :: (f: float) -> int {
    if f > 0 {
        if f - cast(int)f > 0.5 then return cast(int)f + 1;
        else return cast(int)f;
    }
    else {
        if f + cast(int)f < -0.5 then return cast(int)f - 1;
        else return cast(int)f;
    }
}

move_x :: (actor: *Actor, amount: float, on_collide : (actor: *Actor) -> ()) {
    relevant_solids := filter_irrelevant_solids(simulation.solids, actor);

    actor.x_remainder += amount;
    move := round(actor.x_remainder);

    if (move == 0) return;

    actor.x_remainder -= move;
    sign := move / abs(move);

    while move != 0 {
        new_collider := actor.collider;
        new_collider.x = actor.collider.x + sign;

        collides := check_collision_against_all_solids(new_collider, relevant_solids);

        if collides {
            if on_collide != null {
                on_collide(actor);
            }
            break;
        }

        collectibles_overlapped := get_overlapped_collectibles(new_collider, simulation.collectibles);
        for collectibles_overlapped {
            it.collected = true;
        }

        hazards_touched := get_overlapped_hazards(new_collider, simulation.hazards);
        if hazards_touched {
            actor.should_die = true;
        }

        actor.collider.x = new_collider.x;
        move -= sign;
    }
}

move_y :: (actor: *Actor, amount: float, on_collide : (actor: *Actor) -> ()) {
    relevant_solids := filter_irrelevant_solids(simulation.solids, actor);

    actor.y_remainder += amount;
    move := round(actor.y_remainder);

    if (move == 0) return;

    actor.y_remainder -= move;
    sign := move / abs(move);

    while move != 0 {
        new_collider := actor.collider;
        new_collider.y = actor.collider.y + sign;

        collides := check_collision_against_all_solids(new_collider, relevant_solids);

        if collides {
            if on_collide != null {
                on_collide(actor);
            }
            break;
        }

        collectibles_overlapped := get_overlapped_collectibles(new_collider, simulation.collectibles);
        for collectibles_overlapped {
            it.collected = true;
        }

        hazards_touched := get_overlapped_hazards(new_collider, simulation.hazards);
        if hazards_touched {
            actor.should_die = true;
        }

        actor.collider.y = new_collider.y;
        move -= sign;
    }
}

is_riding :: (actor: *Actor, solid: Solid) -> bool {
    extended_collider := actor.collider;
    extended_collider.y -= 1;

    if collision(extended_collider, solid.collider) {
        return true;
    }

    return false;
}

squish :: (actor: *Actor) {
    actor.should_die = true;
    return;
}
