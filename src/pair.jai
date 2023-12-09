// Hal
// Pair
// Alex Hartford
// October 2023

Pair :: struct {
    x : int;
    y : int;
}

operator == :: (a: Pair, b: Pair) -> bool  { return a.x == b.x && a.y == b.y; } #poke_name Basic operator==;
operator +  :: (a: Pair, b: Pair) -> Pair  { return Pair.{a.x + b.x, a.y + b.y}; }
operator -  :: (a: Pair, b: Pair) -> Pair  { return Pair.{a.x - b.x, a.y - b.y}; }
operator *  :: (a: Pair, m: int)   -> Pair { return Pair.{a.x * m, a.y * m}; }
operator *  :: (a: Pair, f: float) -> Pair { return Pair.{xx (a.x * f), xx (a.y * f)}; }
operator /  :: (a: Pair, d: int)   -> Pair { return Pair.{a.x / d, a.y / d}; }

Position :: Pair;
Pixel :: Pair;
Tile_Index :: Pair;
Direction :: Pair;

Invalid_Pair :: Pair.{-1, -1};

Left  :: Pair.{-1,  0 };
Right :: Pair.{ 1,  0 };
Up    :: Pair.{ 0,  1 };
Down  :: Pair.{ 0, -1 };

//

convert_to_pixel :: (floating: Vector2) -> Pair {
    return Pair.{xx floating.x, xx floating.y};
}

convert_to_vector :: (pixel: Pair) -> Vector2 {
    return Vector2.{xx pixel.x, xx pixel.y};
}
