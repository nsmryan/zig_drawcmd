pub const Rect = struct {
    x: i32,
    y: i32,
    w: u32,
    h: u32,

    pub fn init(x: i32, y: i32, w: u32, h: u32) Rect {
        return Rect{ .x = x, .y = y, .w = w, .h = h };
    }
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn init(r: u8, g: u8, b: u8, a: u8) Color {
        return Rect{ .r = r, .g = g, .b = b, .a = a };
    }
};

pub const Pos = struct {
    x: i32,
    y: i32,

    pub fn init(x: i32, y: i32) Pos {
        return Rect{ .x = x, .y = y };
    }
};

pub const Direction = enum {
    right,
    downright,
    down,
    downleft,
    left,
    upleft,
    up,
    upright,
    center,
};
