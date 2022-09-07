const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const sdl2 = @import("sdl2.zig");
const area = @import("area.zig");
const Rect = @import("utils.zig").Rect;

pub const FONT_WIDTH: i32 = 16;
pub const FONT_HEIGHT: i32 = 16;

pub const SpriteIndex = u32;
pub const SpriteKey = u32;

pub const Sprite = struct {
    index: SpriteIndex,
    key: SpriteKey,
    flip_horiz: bool = false,
    flip_vert: bool = false,
    rotation: f64 = 0.0,

    pub fn init(index: SpriteIndex, key: SpriteKey) Sprite {
        return Sprite{ .index = index, .key = key };
    }

    pub fn fromKey(key: SpriteKey) Sprite {
        Sprite.init(0, key);
    }

    pub fn withFlip(index: SpriteIndex, key: SpriteKey, flip_horiz: bool, flip_vert: bool) Sprite {
        return Sprite{ .index = index, .key = key, .flip_horiz = flip_horiz, .flip_vert = flip_vert };
    }
};

// NOTE consider an interned string for the name instead of a fixed size buffer
pub const SpriteSheet = struct {
    name: [64]u8,
    num_sprites: usize,
    rows: usize,
    cols: usize,
    width: usize,
    height: usize,
    x_offset: u32,
    y_offset: u32,

    pub fn init(name: [64]u8, num_sprites: usize, rows: usize, cols: usize, width: usize, height: usize, x_offset: u32, y_offset: u32) SpriteSheet {
        return SpriteSheet{ .name = name, .num_sprites = num_sprites, .rows = rows, .cols = cols, .width = width, .height = height, .x_offset = x_offset, .y_offset = y_offset };
    }

    pub fn withOffset(name: [64]u8, x_offset: u32, y_offset: u32, width: usize, height: usize) SpriteSheet {
        const rows = @intCast(usize, height / FONT_HEIGHT);
        const cols = @intCast(usize, width / FONT_WIDTH);
        const num_sprites = cols * rows;

        return SpriteSheet{
            .name = name,
            .num_sprites = num_sprites,
            .rows = rows,
            .cols = cols,
            .width = width,
            .height = height,
            .x_offset = x_offset,
            .y_offset = y_offset,
        };
    }

    pub fn single(name: [64]u8, width: usize, height: usize) SpriteSheet {
        const num_sprites = 1;
        const rows = 1;
        const cols = 1;
        const x_offset = 0;
        const y_offset = 0;

        return SpriteSheet{
            .name = name,
            .num_sprites = num_sprites,
            .rows = rows,
            .cols = cols,
            .width = width,
            .height = height,
            .x_offset = x_offset,
            .y_offset = y_offset,
        };
    }

    pub fn numCells(self: *SpriteSheet) area.Dims {
        return .{ self.cols, self.rows };
    }

    pub fn numPixels(self: *SpriteSheet) area.Dims {
        return area.Dims.init(self.width, self.height);
    }

    pub fn spriteDims(self: *SpriteSheet) area.Dims {
        const cell_dims = self.numCells();
        return area.Dims.init(self.width / cell_dims.width, self.height / cell_dims.height);
    }

    // Get the source rectangle for a particular sprite given by its index into the sprite sheet.
    pub fn spriteSrc(self: *SpriteSheet, origIndex: u32) Rect {
        const cell_dims = self.numCells();
        const index = @intCast(usize, origIndex);
        const sprite_x = index % cell_dims.width;
        const sprite_y = index / cell_dims.width;

        const sprite_dims = self.sprite_dims();
        //const sprite_width = cell_dims.width;
        //const sprite_height = cell_dims.height;

        const x = @intCast(i32, self.x_offset) + @intCast(i32, sprite_x * sprite_dims.width);
        const y = @intCast(i32, self.y_offset) + @intCast(i32, sprite_y * sprite_dims.height);
        const w = @intCast(u32, sprite_dims.width);
        const h = @intCast(u32, sprite_dims.height);
        const src = Rect{ .x = x, .y = y, .w = w, .h = h };

        return src;
    }
};

const ParseAtlasError = error{
    SpriteNameTooLong,
    MissingField,
};

pub fn parseAtlasFile(atlas_file: []u8, allocator: Allocator) !ArrayList(SpriteSheet) {
    var file = try std.fs.cwd().openFile(atlas_file, .{});
    defer file.close();

    var sheets = ArrayList(SpriteSheet).init(allocator);
    errdefer sheets.deinit();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const parts = std.mem.split(u8, line, ' ');

        const spriteName = parts.next() orelse return ParseAtlasError.MissingField;
        if (spriteName.len > @sizeOf(SpriteSheet.name)) {
            // NOTE(log) log length and name.
            return ParseAtlasError.SpriteNameTooLong;
        }

        var name: [64]u8 = [_]u8{0} * 64;
        std.mem.copy(u8, name, spriteName);
        const x = try std.fmt.parseInt(u32, parts.next orelse return ParseAtlasError.MissingField);
        const y = try std.fmt.parseInt(u32, parts.next orelse return ParseAtlasError.MissingField);
        const width = try std.fmt.parseInt(usize, parts.next orelse return ParseAtlasError.MissingField);
        const height = try std.fmt.parseInt(usize, parts.next orelse return ParseAtlasError.MissingField);

        var sheet = SpriteSheet.with_offset(name, x, y, width, height);

        // Button sprites are handled specially - they are always a single large sprite.
        if (std.mem.startsWith(u8, name, "Button")) {
            sheet.rows = 1;
            sheet.cols = 1;
            sheet.num_sprites = 1;
        }

        sheets.append(sheet);
    }

    return sheets;
}

const SpriteLookupError = error{
    SpriteNameNotFound,
};

pub fn lookupSpritekey(sprites: *ArrayList(SpriteSheet), name: []u8) !SpriteKey {
    for (sprites.iter()) |sprite_sheet, index| {
        // NOTE this assumes zero padding. An interned string is a better solution.
        if (std.mem.eql(u8, sprite_sheet.name[0..], name)) {
            return index;
        }
    }

    // NOTE(log) log the missing name.
    return SpriteLookupError.SpriteNameNotFound;
}
