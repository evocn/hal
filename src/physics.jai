// Hal
// Physics
// Alex Hartford
// October 2023

Rect :: struct {
    position : Vector2;
    size : Vector2;
}

draw :: (rect: Rect, color := gray) {
    draw_colored_rectangle(xx rect.position.x, xx rect.position.y, xx rect.size.x, xx rect.size.y, color=color);
}

//

Ray :: struct {
    position : Vector2;
    direction: Vector2;
}

//
// Static Collisions ///////////////////////////////////////////////////////////
//

collision :: (point: Vector2, rect: Rect) -> bool {
    return point.x >= rect.position.x 
        && point.y >= rect.position.y 
        && point.x <= rect.position.x + rect.size.x 
        && point.y <= rect.position.y + rect.size.y;
}

collision :: (a: Rect, b: Rect) -> bool {
    return a.position.x < b.position.x + b.size.x
        && a.position.y < b.position.y + b.size.y
        && a.position.x + a.size.x > b.position.x
        && a.position.y + a.size.y > b.position.y;
}

//
// Swept Collisions ////////////////////////////////////////////////////////////
//

Swept_Collision :: struct {
    collided : bool;
    point : Vector2;
    normal : Vector2;
    t : float;
}

// represents a ray's intersection with a rectangle.
// Returns the point on the near side of the rectangle where it first intersects,
// along with the normal of the rectangle at that point, and the t value on the
// ray where the intersection occurred.
collision :: (ray: Ray, rect: Rect) -> Swept_Collision
{
    inverse_direction := 1.0 / ray.direction;
    time_near := (rect.position - ray.position) * inverse_direction;
    time_far  := (rect.position + rect.size - ray.position) * inverse_direction;

    is_nan :: (f: float) -> bool { return f == FLOAT32_NAN; }
    if is_nan(time_far.y)  || is_nan(time_far.x) || is_nan(time_near.y) || is_nan(time_near.x)
        return .{};

    // Sort distances
    if time_near.x > time_far.x
        time_near.x, time_far.x = swap(time_near.x, time_far.x);
    if time_near.y > time_far.y
        time_near.y, time_far.y = swap(time_near.y, time_far.y);

    // Early Rejection
    if time_near.x > time_far.y || time_near.y > time_far.x return .{};

    // First contact
    time_hit_near := max(time_near.x, time_near.y);
    time_hit_far := min(time_far.x, time_far.y);

    if time_hit_far < 0 return .{};

    contact_point := ray.position + time_hit_near * ray.direction;

    contact_normal : Vector2;
    if time_near.x > time_near.y {
        if inverse_direction.x < 0
            contact_normal = .{1, 0};
        else
            contact_normal = .{-1, 0};
    }
    else if time_near.x < time_near.y {
        if inverse_direction.y < 0
            contact_normal = .{0, 1};
        else
            contact_normal = .{0, -1};
    }

    return .{true, contact_point, contact_normal, time_hit_near};
}

//

// Represents a collision between a moving rectangle and a static rectangle.
collision :: (moving: Rect, velocity : Vector2, static: Rect) -> Swept_Collision
{
    expanded_target : Rect;
    expanded_target.position = static.position - (moving.size / 2);
    expanded_target.size = static.size + moving.size;

    ray := Ray.{position  = moving.position + (moving.size / 2), 
                direction = velocity}; // @TODO: Should this be times dt?
    the_collision := collision(ray, expanded_target);
    if the_collision.collided {
        the_collision.collided = (the_collision.t >= 0.0 && the_collision.t < 1.0);
        return the_collision;
    }
    return .{};
}
