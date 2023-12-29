// Hal
// Tiles
// Alex Hartford
// October 2023

Tile :: struct {
    using properties : Tile_Properties;

    // State
    union {
        solid: Solid;
        collectible: Collectible;
        hazard: Hazard;
    }
}

Tile_Properties :: struct {
    catalogue_index : int;
    name: string;

    kind : Tile_Kind;

    collider_kind : Tile_Collider_Kind = .FULL_BOX;
    collectible_kind : Collectible_Kind = .NONE;

    flags : Tile_Flags;

    sprite : int;
    color : Color = white;
}

Tile_Kind :: enum {
    EMPTY;
    SOLID;
    HAZARD;
    COLLECTIBLE;
}

Tile_Collider_Kind :: enum {
    FULL_BOX;
    NONE;
    TOP_HALF;
    BOTTOM_HALF;
    CENTER;
}

Tile_Flags :: enum_flags {
    ONE_WAY;
}

tile_catalogue := Tile_Properties.[
    .{
        catalogue_index = 0,
        kind = .EMPTY,
        collider_kind = .NONE,
    },

    .{
        catalogue_index = 1,
        name = "platform", 
        kind = .SOLID,
        collider_kind = .TOP_HALF,
        flags = .ONE_WAY,
        sprite = 4,
        color = white,
    },

    .{
        catalogue_index = 2,
        name = "wall", 
        kind = .SOLID,
        sprite = 15,
        color = white,
    },

    .{
        catalogue_index = 3, 
        name = "spike",
        kind = .HAZARD,
        collider_kind = .BOTTOM_HALF,
        sprite = 23,
        color = red,
    },

    .{
        catalogue_index = 4,
        name = "stalagtite",
        kind = .HAZARD,
        collider_kind = .TOP_HALF,
        sprite = 19,
        color = red,
    },

    .{
        catalogue_index = 5,
        name = "coin",
        collider_kind = .CENTER,
        kind = .COLLECTIBLE,
        collectible_kind = .COIN,
        sprite = 30,
        color = yellow,
    },

    .{
        catalogue_index = 6,
        name = "gem",
        kind = .COLLECTIBLE,
        collider_kind = .CENTER,
        collectible_kind = .GEM,
        sprite = 31,
        color = green,
    },
];

get_collider_for_tile :: (kind: Tile_Collider_Kind, col: int, row: int) -> Collider {
    if #complete kind == {
        case .NONE;
            return .{};
        case .FULL_BOX;
            return Collider.{
                x = col * TILE_SIZE_IN_PIXELS,
                y = row * TILE_SIZE_IN_PIXELS,
                width = TILE_SIZE_IN_PIXELS,
                height = TILE_SIZE_IN_PIXELS,
            };

        case .TOP_HALF;
            return Collider.{
                x = col * TILE_SIZE_IN_PIXELS,
                y = row * TILE_SIZE_IN_PIXELS + TILE_SIZE_IN_PIXELS / 2,
                width = TILE_SIZE_IN_PIXELS,
                height = TILE_SIZE_IN_PIXELS / 2,
            };

        case .BOTTOM_HALF;
            return Collider.{
                x = col * TILE_SIZE_IN_PIXELS,
                y = row * TILE_SIZE_IN_PIXELS,
                width = TILE_SIZE_IN_PIXELS,
                height = TILE_SIZE_IN_PIXELS / 2,
            };

        case .CENTER;
            return Collider.{
                x = col * TILE_SIZE_IN_PIXELS + TILE_SIZE_IN_PIXELS / 4,
                y = row * TILE_SIZE_IN_PIXELS + TILE_SIZE_IN_PIXELS / 4,
                width = TILE_SIZE_IN_PIXELS / 2,
                height = TILE_SIZE_IN_PIXELS / 2,
            };
    }
}

generate_tile :: (col: int, row: int, catalogue_index : int) -> Tile {
    new_tile : Tile;
    new_tile.properties = tile_catalogue[catalogue_index];

    if #complete new_tile.properties.kind == {
        case .EMPTY;

        case .HAZARD; 
            new_tile.hazard.collider = get_collider_for_tile(new_tile.collider_kind, col, row);

        case .SOLID;
            new_tile.solid.collider = get_collider_for_tile(new_tile.collider_kind, col, row);
            if new_tile.flags & .ONE_WAY {
                new_tile.solid.one_way = true;
            }

        case .COLLECTIBLE;
            new_tile.collectible.collider = get_collider_for_tile(new_tile.collider_kind, col, row);
            // @CLEANUP - this shouldn't have to be duplicated.
            new_tile.collectible.kind = new_tile.collectible_kind;
    }

    return new_tile;
}

generate_and_set_tile :: (level: *Level, col: int, row: int, catalogue_index : int) {
    index := row * level.width + col;
    level.tiles[index] = generate_tile(col, row, catalogue_index);
}

