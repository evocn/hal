// Hal
// Player
// Alex Hartford
// October 2023

Player :: struct {
    using actor : Actor;
    width = 8;
    height = 10;

    velocity    : Vector2;
    grounded    : bool;

    dead        : bool;

    coyote_time : float;

    animation_state : Player_Animation_State;
    animation_machine : Animation_Machine;
    sprite: int = 32;
    orientation: Direction;
}

Player_Animation_State :: enum {
    IDLE;
    WALK;
    GLIDE;
    FALL;
    JUMP;
}


MINIMUM_WALK_SPEED   :: 10.0;
MAXIMUM_WALK_SPEED   :: 60.0;
WALK_ACCELERATION    :: 2.0;
RELEASE_DECELERATION :: 8.0;

// Vertical
JUMP_VELOCITY   :: 110.0;
FALLING_GRAVITY :: 5.0;
TERMINAL_FALLING_VELOCITY :: 100.0;
HOLDING_GRAVITY :: 2.0;
TERMINAL_GLIDING_VELOCITY :: 12.0;

COYOTE_TIME_MARGIN  :: 0.1;

update :: (player : *Player, level: Level, dt: float) {
    // Always Updating
    {
        player.coyote_time = max(0.0, player.coyote_time - dt);

        update_appearance(player, dt);
    }

    // Move the Player Actor.
    {
        move_x(*player.actor, player.velocity.x * dt, null);
        move_y(*player.actor, player.velocity.y * dt, null);

        // Check if the player's dead.
        {
            if player.actor.should_die {
                player.dead = true;
            }

            if player.y + TILE_SIZE_IN_PIXELS < 0 {
                player.dead = true;
            }
        }

        clamp_player_to_level_boundary(player, level.width * TILE_SIZE_IN_PIXELS, level.height * TILE_SIZE_IN_PIXELS);
    }

    // Determine new grounded state.
    if player.velocity.y <= 0.0 {
        grounded_now := check_if_grounded(player.actor);

        if grounded_now {
            player.coyote_time = COYOTE_TIME_MARGIN;
            player.velocity.y = 0.0;
        }

        player.grounded = grounded_now;
    }

    if player.velocity.y > 0.0 {
        hitting_head_now := check_if_hitting_head(player.actor);
        if hitting_head_now {
            player.velocity.y = 0.0;
        }
    }

    // Update Debug Info.
    {
        if debug {
            dprint(sprint("P: % %", player.x, player.y));
            dprint(sprint("V: %", player.velocity));
            dprint(sprint("G: %", player.grounded));
        }
    }
}


resolve_player_inputs :: (input: Input, player : *Player) {
    {
        left  := button_is_held(input, .LEFT);
        right := button_is_held(input, .RIGHT);

        // Update Velocity based on inputs
        if right && !left {
            player.velocity.x = max(player.velocity.x, MINIMUM_WALK_SPEED);
            player.velocity.x += WALK_ACCELERATION;
            player.velocity.x = min(player.velocity.x, MAXIMUM_WALK_SPEED);
        }
        else if left && !right {
            player.velocity.x = min(player.velocity.x, -1 * MINIMUM_WALK_SPEED);
            player.velocity.x += -1 * WALK_ACCELERATION;
            player.velocity.x = max(player.velocity.x, -1 * MAXIMUM_WALK_SPEED);
        }
        else {
            if player.velocity.x < 0 {
                player.velocity.x += RELEASE_DECELERATION;
                player.velocity.x = min(0.0, player.velocity.x);
            }
            else if player.velocity.x > 0 {
                player.velocity.x -= RELEASE_DECELERATION;
                player.velocity.x = max(0.0, player.velocity.x);
            }
        }
    }

    {
        jump :: (player: *Player) {
            player.velocity.y = JUMP_VELOCITY;
            player.grounded = false;

            player.coyote_time = 0.0;
        }

        // Apply Gravity
        if player.grounded {
            if button_was_just_pressed(input, .A) {
                jump(player);
            }
        }
        else {
            if player.velocity.y >= 0 && button_is_held(input, .A) {
                player.velocity.y -= HOLDING_GRAVITY;
            }
            else {
                player.velocity.y -= FALLING_GRAVITY;
            }

            if player.velocity.y <= -TERMINAL_GLIDING_VELOCITY && button_is_held(input, .A) {
                player.velocity.y = -TERMINAL_GLIDING_VELOCITY;
            }


            if player.coyote_time > 0.0 && button_was_just_pressed(input, .A) {
                jump(player);
            }
        }

        player.velocity.y = max(player.velocity.y, -TERMINAL_FALLING_VELOCITY);
    }
}


resolve_player_inputs_for_appearance :: (input: Input, player : *Player) {
    // Orientation
    left    := button_is_held(input, .LEFT);
    right   := button_is_held(input, .RIGHT);
    if left {
        player.orientation = Left;
    }
    else if right {
        player.orientation = Right;
    }


    // Animation
    if player.grounded {
        if (left | right) && !(left && right) {
            go_to_state(player, .WALK);
        }
        else {
            go_to_state(player, .IDLE);
        }
    }
    else {
        if player.velocity.y > 0 {
            go_to_state(player, .JUMP);
        }
        else if player.velocity.y < -TERMINAL_GLIDING_VELOCITY {
            go_to_state(player, .FALL);
        }
        else {
            go_to_state(player, .GLIDE);
        }
    }
}

//
//
//

move_here_dumb :: (player: *Player, x: int, y: int) {
    player.x = x;
    player.y = y;

    player.actor.x_remainder = 0;
    player.actor.y_remainder = 0;
}

neutralize :: (player: *Player) {
    player.dead = false;
    player.actor.should_die = false;
    player.velocity = .{};
}


//
//
//

go_to_state :: (player: *Player, new_state: Player_Animation_State) {
    if player.animation_state == new_state then return;
    player.animation_state = new_state;

    if player.animation_state == {
        case .IDLE;
            start(*player.animation_machine.animations[0]);

        case .WALK;
            start(*player.animation_machine.animations[1]);

        case .GLIDE;
            player.sprite = 42;

        case .FALL;
            player.sprite = 43;

        case .JUMP;
            player.sprite = 45;
    }
}

update_appearance :: (player: *Player, dt: float) {
    if player.animation_state == {
        case .IDLE;
            update(*player.animation_machine.animations[0], dt);

        case .WALK;
            update(*player.animation_machine.animations[1], dt);

        case .GLIDE;
        case .FALL;
        case .JUMP;
    }
}
