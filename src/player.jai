// Hal
// Player
// Alex Hartford
// October 2023

player_state : struct {
    coins : int;
}

GUY_COLLISION_BOX_WIDTH :: 8.0;
GUY_COLLISION_BOX_HEIGHT :: 10.0;

Guy :: struct {
    // State
    position : Vector2;
    velocity : Vector2;
    grounded : bool = true;
    dead : bool;
    midair_jump_available : bool = true;
    coyote_time : float = 0.0;

    collision_box : Rect;

    // Visuals
    frame : int;
    orientation := Right;
    state : Guy_State;

    // Animations
    idle_anim  : Anim;
    walk_anim  : Anim;
}

Guy_State :: enum {
    IDLE;
    WALK;
    GLIDE;
    FALL;
    JUMP;
}

go_to_state :: (guy: *Guy, state: Guy_State) {
    if guy.state == state then return;

    guy.state = state;

    // State transitions
    if state == {
        case .IDLE;
            begin(*guy.idle_anim);

        case .WALK;
            begin(*guy.walk_anim);

        case .GLIDE;
            guy.frame = 42;

        case .FALL;
            guy.frame = 43;

        case .JUMP;
            guy.frame = 45;
    }
}

neutralize :: (guy: *Guy) {
    guy.dead = false;
    guy.velocity = .{};
    guy.orientation = Right;
}

//

update :: (guy: *Guy, dt: float) {
    guy.coyote_time = max(0.0, guy.coyote_time - dt);

    if guy.state == {
        case .IDLE;
            update(*guy.idle_anim, dt);

        case .WALK;
            update(*guy.walk_anim, dt);

        case .GLIDE;
        case .FALL;
        case .JUMP;
    }
}

//

resolve_player_inputs :: (guy : *Guy, level: Level, dt: float) {
    using input;

    // Constants ///////////////////////////////////////////////////////////////
    // Horizontal
    MINIMUM_WALK_SPEED   :: 10.0;
    MAXIMUM_WALK_SPEED   :: 60.0;
    WALK_ACCELERATION    :: 2.0;
    RELEASE_DECELERATION :: 8.0;

    // Vertical
    JUMP_VELOCITY   :: 110.0;
    MIDAIR_JUMP_VELOCITY   :: 80.0;
    FALLING_GRAVITY :: 4.0;
    TERMINAL_FALLING_VELOCITY :: 100.0;
    HOLDING_GRAVITY :: 2.0;
    TERMINAL_GLIDING_VELOCITY :: 16.0;

    DEFAULT_COYOTE_TIME_MARGIN :: 0.1;

    //
    
    { // Horizontal
        // Get directional inputs
        left := button_is_held(.LEFT);
        right := button_is_held(.RIGHT);

        // Update Velocity based on inputs
        if right && !left {
            guy.velocity.x = max(guy.velocity.x, MINIMUM_WALK_SPEED);
            guy.velocity.x += WALK_ACCELERATION;
            guy.velocity.x = min(guy.velocity.x, MAXIMUM_WALK_SPEED);
        }
        else if left && !right {
            guy.velocity.x = min(guy.velocity.x, -1 * MINIMUM_WALK_SPEED);
            guy.velocity.x += -1 * WALK_ACCELERATION;
            guy.velocity.x = max(guy.velocity.x, -1 * MAXIMUM_WALK_SPEED);
        }
        else {
            if guy.velocity.x < 0 {
                guy.velocity.x += RELEASE_DECELERATION;
                guy.velocity.x = min(0.0, guy.velocity.x);
            }
            else if guy.velocity.x > 0 {
                guy.velocity.x -= RELEASE_DECELERATION;
                guy.velocity.x = max(0.0, guy.velocity.x);
            }
        }
    }

    { // Vertical
        jump :: (guy: *Guy) {
            guy.velocity.y = JUMP_VELOCITY;
            guy.grounded = false;
            guy.coyote_time = 0.0;
        }

        midair_jump :: (guy: *Guy) {
            guy.velocity.y = MIDAIR_JUMP_VELOCITY;
            guy.grounded = false;
            guy.coyote_time = 0.0;
            guy.midair_jump_available = false;
        }

        // Apply Gravity
        if !guy.grounded {
            if guy.coyote_time > 0.0 && button_was_just_pressed(.A) {
                jump(guy);
            }

            /*
            else if button_was_just_pressed(.B) && guy.midair_jump_available {
                midair_jump(guy);
            }
            */

            if guy.velocity.y >= 0 && button_is_held(.A) {
                guy.velocity.y -= HOLDING_GRAVITY;
            }
            else {
                guy.velocity.y -= FALLING_GRAVITY;
            }

            if guy.velocity.y <= -TERMINAL_GLIDING_VELOCITY && button_is_held(.A) {
                guy.velocity.y = -TERMINAL_GLIDING_VELOCITY;
            }
        }
        else {
            if button_was_just_pressed(.A) {
                jump(guy);
            }
        }

        guy.velocity.y = max(guy.velocity.y, -TERMINAL_FALLING_VELOCITY);
    }

    //
    // Physics /////////////////////////////////////////////////////////////////
    //

    // @CONSIDER:
    // Celeste does things much simpler than this... Let's think about it.
    // The general idea:
    // * Movement happens in one axis at a time, one pixel at a time.
    // * MoveX is given an amount in pixels, and it loops one pixel at a time, checking for collisions.
    //   If it happens, then usually the movement simply stops. That's it.
    // Let's do it!


    additional_velocity_from_outside_sources : Vector2;
    //additional_velocity_from_outside_sources += get_velocity_generated_from_wind_streams(guy.*, level.wind_streams);

    guy.velocity += additional_velocity_from_outside_sources;

    // @SPEED: Just check collisions against nearby tiles...
    tiles := gather_all_tiles_with_collision_boxes(level);

    old_position := guy.position;
    new_position := guy.position + guy.velocity * dt;

    { // Ballistic Motion
        for tile: tiles {
            target := *tile.collision_box;
            expanded_target : Rect;
            expanded_target.position = target.position - (guy.collision_box.size / 2);
            expanded_target.size = target.size + guy.collision_box.size;

            ray := Ray.{
                position = guy.collision_box.position + (guy.collision_box.size / 2), 
                direction = guy.velocity * dt
            };

            the_collision := collision(ray, expanded_target);

            // If colliding, resolve.
            if the_collision.collided && the_collision.t >= 0 && the_collision.t <= 1 {
                if (tile.properties & .KILL) {
                    guy.dead = true;
                    break;
                }

                if (tile.properties & .ONE_WAY) {
                    if guy.position.y < target.position.y + target.size.y {
                        continue;
                    }
                }

                if (tile.properties & .COIN) {
                    player_state.coins += 1;
                    tile.should_disappear = true;
                    continue;
                }

                if (tile.properties & .GEM) {
                    player_state.coins += 5;
                    tile.should_disappear = true;
                    continue;
                }

                guy.velocity += the_collision.normal * Vector2.{xx abs(guy.velocity.x), xx abs(guy.velocity.y)} * (1 - the_collision.t);
                new_position = guy.position + guy.velocity * dt;
            }
        }
    }

    // Check if we are grounded!
    {
        is_grounded_now := check_if_guy_is_grounded(guy, tiles, dt);
        used_to_be_grounded := guy.grounded;

        just_left_the_ground := used_to_be_grounded && !is_grounded_now;
        if just_left_the_ground {
            guy.coyote_time = DEFAULT_COYOTE_TIME_MARGIN;
        }

        just_landed := is_grounded_now && !used_to_be_grounded;
        if just_landed {
            guy.midair_jump_available = true;
        }

        guy.grounded = is_grounded_now;
    }

    // Update Things
    guy.position = new_position;

    // Apply General constraints
    if guy.position.x <= 0 {
        guy.position.x = 0;
    }

    right_boundary := cast(float)(level.columns.count * TILE_SIZE_IN_PIXELS - TILE_SIZE_IN_PIXELS);
    if guy.position.x >= right_boundary {
        guy.position.x = right_boundary;
    }

    guy.collision_box.position.x = cast(float)(guy.position.x + (GUY_COLLISION_BOX_WIDTH - guy.collision_box.size.x / 2));
    guy.collision_box.position.y = cast(float)(guy.position.y);

    if guy.position.y <= -TILE_SIZE_IN_PIXELS {
        guy.dead = true;
    }

    // @ROBUSTNESS:
    // * Maybe do a fallthrough check to see if we're statically intersecting any and adjust for that? We don't want to get stuck, ever.
    // * Sort all collisions and apply the earliest ones first?

    //
    // Visual Updates //////////////////////////////////////////////////////////
    //
    {
        // Orientation
        left := button_is_held(.LEFT);
        right := button_is_held(.RIGHT);
        if left {
            guy.orientation = Left;
        }
        else if right {
            guy.orientation = Right;
        }

        // Animation
        if guy.grounded {
            if (left | right) && !(left && right) {
                go_to_state(guy, .WALK);
            }
            else {
                go_to_state(guy, .IDLE);
            }
        }
        else {
            if guy.velocity.y > 0 {
                go_to_state(guy, .JUMP);
            }
            else if guy.velocity.y < -TERMINAL_GLIDING_VELOCITY {
                go_to_state(guy, .FALL);
            }
            else {
                go_to_state(guy, .GLIDE);
            }
        }
    }

    // Debug Print
    if debug {
        dprint(sprint("P: %", guy.position));
        dprint(sprint("V: %", guy.velocity));
        dprint(sprint("G: %", guy.grounded));
    }
}

//
// Physics Logic ///////////////////////////////////////////////////////////////
//

check_if_guy_is_grounded :: (guy: Guy, tiles : [] *Tile, dt: float) -> is_grounded: bool {
    for tile: tiles {
        target := *tile.collision_box;

        expanded_target : Rect;
        expanded_target.position = target.position - (guy.collision_box.size / 2);
        expanded_target.size = target.size + guy.collision_box.size;

        ray := Ray.{
            position = guy.collision_box.position + (guy.collision_box.size / 2),
            direction = Vector2.{0, -1} * dt
            // @NOTE: I haven't fully thought this dt through, but it seems to work!
        };

        the_collision := collision(ray, expanded_target);
        if the_collision.collided && the_collision.t >= 0 && the_collision.t <= 1 {
            return true;
        }
    }

    return false;
}

move_here_dumb :: (guy: *Guy, position: Vector2) {
    guy.position = position;

    guy.collision_box.position.x = cast(float)(guy.position.x + (8 - guy.collision_box.size.x / 2));
    guy.collision_box.position.y = cast(float)(guy.position.y);
}
