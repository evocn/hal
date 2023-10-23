// Hal
// Level
// Alex Hartford
// October 2023

LEVEL_HEIGHT :: 18;

Level :: struct {
    shortname : string;
    next_level_name : string;

    start : Tile_Index;
    end : Tile_Index;

    // Various features of the level
    columns : [..] Tile_Column;
    wind_streams : [..] Wind_Stream;
}
Tile_Column :: [LEVEL_HEIGHT] Tile;

wipe :: (level: *Level) {
    for col: 0..level.columns.count-1 {
        for row: 0..LEVEL_HEIGHT-1 {
            set_tile(level, .{col, row}, 0);
        }
    }
    level.start = .{0, 0};
    level.end = .{1, 0};
}

//

// Returns a temp allocated list of pointers to all the rectangles in the given level.
gather_all_tiles_with_collision_boxes :: (level: Level) -> [] *Tile {
    result : [..] *Tile;
    result.allocator = temp;

    for level.columns {
        for tile: it {
            if tile.collidable {
                array_add(*result, *tile);
            }
        }
    }

    return result;
}

// @TODO: Only check collisions against local boxes.
// Look into the best way to keep it local and also accurate.

/*
Tile_Locator :: struct {
    col: int;
    row: int;
}

// Returns a temp allocated list of pointers to rectangles on the given level that overlap with the given rect.
query_collision_boxes :: (level: Level, position_in_pixels: Vector2) -> [] *Rect {
    result : [..] *Rect;
    result.allocator = temp;

    query_tile_for_collision_box :: (level: Level, using locator: Tile_Locator) -> *Rect {
        if col < 0 || row < 0 || row > 8 {
            //print("You shouldn't be making this query! Something's not going to be on the level. Your query: (%, %).\n", col, row);
            return null;
        }
        if col >= level.columns.count {
            //print("Warning: You're querying a tile that doesn't exist because this map is not long enough! Your query: (%, %).\n", col, row);
            return null;
        }

        tile := *level.columns[col][row];
        if tile.collidable {
            return *tile.collision_box;
        }

        return null;
    }

    position := position_in_pixels / TILE_SIZE;

    // Test against the nearest 9!
    locators : [9] Tile_Locator;
    locators[0] = .{cast(int)position.x,     cast(int)position.y    };
    locators[1] = .{cast(int)position.x + 1, cast(int)position.y    };
    locators[2] = .{cast(int)position.x    , cast(int)position.y + 1};
    locators[3] = .{cast(int)position.x + 1, cast(int)position.y + 1};
    locators[4] = .{cast(int)position.x - 1, cast(int)position.y    };
    locators[5] = .{cast(int)position.x    , cast(int)position.y - 1};
    locators[6] = .{cast(int)position.x - 1, cast(int)position.y - 1};
    locators[7] = .{cast(int)position.x - 1, cast(int)position.y + 1};
    locators[8] = .{cast(int)position.x + 1, cast(int)position.y - 1};

    for locators {
        collision_box := query_tile_for_collision_box(level, it);
        if collision_box then 
            array_add(*result, collision_box);
    }

    return result;
}
*/
