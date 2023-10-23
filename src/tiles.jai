// Hal
// Tiles
// Alex Hartford
// October 2023

Tile :: struct {
    // Properties
    index: int;
    name: string;
    collidable : bool;
    collision_box_kind : Tile_Collision_Box_Kind = .FULL_BOX;
    properties : Tile_Properties;

    // Cosmetic
    background : int;
    color : Color = white;

    // State
    collision_box: Rect;
    should_disappear : bool;
}

Tile_Properties :: enum_flags {
    KILL;
    ONE_WAY;
    COIN;
    GEM;
}

Tile_Collision_Box_Kind :: enum {
    FULL_BOX;
    TOP_HALF;
    BOTTOM_HALF;
    CENTER;
}

tile_catalogue := Tile.[
    .{},
    .{index=1, name="platform", collidable = true, collision_box_kind = .TOP_HALF, properties=.ONE_WAY, background = 4, color = white},
    .{index=2, name="wall", collidable = true, background = 15, color=white},
    .{index=3, name="spike", collidable = true, collision_box_kind = .BOTTOM_HALF, properties=.KILL, background = 23, color=color_2},
    .{index=4, name="stalagtite", collidable = true, collision_box_kind = .TOP_HALF, properties=.KILL, background = 19, color=color_2},
    .{index=5, name="coin", collidable = true, collision_box_kind = .CENTER, properties=.COIN, background = 30, color=color_4},
    .{index=6, name="gem", collidable = true, collision_box_kind = .CENTER, properties=.GEM, background = 31, color=color_3},
];

set_tile :: (level: *Level, index: Tile_Index, catalogue_index : int) {
    col := index.x; row := index.y;
    level.columns[col][row] = tile_catalogue[catalogue_index];

    if #complete level.columns[col][row].collision_box_kind == {

        // @TODO: Smaller hitboxes for spike things so that you don't rely on ordering to avoid them.
        case .FULL_BOX;
        level.columns[col][row].collision_box = Rect.{.{xx (col * TILE_SIZE), xx (row * TILE_SIZE)}, .{TILE_SIZE, TILE_SIZE}};

        case .TOP_HALF;
        level.columns[col][row].collision_box = Rect.{.{xx (col * TILE_SIZE), xx (row * TILE_SIZE + TILE_SIZE / 2)}, .{TILE_SIZE, TILE_SIZE / 2}};

        case .BOTTOM_HALF;
        level.columns[col][row].collision_box = Rect.{.{xx (col * TILE_SIZE), xx (row * TILE_SIZE)}, .{TILE_SIZE, TILE_SIZE / 2}};

        case .CENTER;
        level.columns[col][row].collision_box = Rect.{.{xx (col * TILE_SIZE + TILE_SIZE / 4), xx (row * TILE_SIZE + TILE_SIZE / 4)}, .{TILE_SIZE / 2, TILE_SIZE / 2}};
    }
}

