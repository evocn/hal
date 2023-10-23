// Hal
// Pixel
// Alex Hartford
// October 2023

Pixel :: struct {
    x : int;
    y : int;
}

operator == :: (a: Pixel, b: Pixel) -> bool   { return a.x == b.x && a.y == b.y; } #poke_name Basic operator==;
operator +  :: (a: Pixel, b: Pixel) -> Pixel  { return Pixel.{a.x + b.x, a.y + b.y}; }
operator -  :: (a: Pixel, b: Pixel) -> Pixel  { return Pixel.{a.x - b.x, a.y - b.y}; }
operator *  :: (a: Pixel, m: int)   -> Pixel  { return Pixel.{a.x * m, a.y * m}; }
operator *  :: (a: Pixel, f: float) -> Pixel  { return Pixel.{xx (a.x * f), xx (a.y * f)}; }
operator /  :: (a: Pixel, d: int)   -> Pixel  { return Pixel.{a.x / d, a.y / d}; }

Invalid_Pixel :: Pixel.{-1, -1};

LEFT  :: Pixel.{-1,  0 };
RIGHT :: Pixel.{ 1,  0 };
UP    :: Pixel.{ 0,  1 };
DOWN  :: Pixel.{ 0, -1 };

//

convert_to_pixel :: (floating: Vector2) -> Pixel {
    return Pixel.{xx floating.x, xx floating.y};
}

convert_to_vector :: (pixel: Pixel) -> Vector2 {
    return Vector2.{xx pixel.x, xx pixel.y};
}
