const sprite = @import("sprite.zig");
const Sprite = sprite.Sprite;
const utils = @import("utils.zig");
const Color = utils.Color;
const Pos = utils.Pos;
const Direction = utils.Direction;

pub const Justify = enum {
    right,
    center,
    left,
};

pub const DrawSprite = struct { sprite: Sprite, color: Color, pos: Pos };
pub const DrawSpriteScaled = struct { sprite: Sprite, scale: f32, dir: Direction, color: Color, pos: Pos };
pub const DrawSpriteFloat = struct { sprite: Sprite, color: Color, x: f32, y: f32, x_scale: f32, y_scale: f32 };
pub const DrawHighlightTile = struct { color: Color, pos: Pos };
pub const DrawOutlineTile = struct { color: Color, pos: Pos };
pub const DrawText = struct { text: [64]u8, color: Color, pos: Pos, scale: f32 };
pub const DrawTextFloat = struct { text: [64]u8, color: Color, x: f32, y: f32, scale: f32 };
pub const DrawTextJustify = struct { text: [64]u8, justify: Justify, fg_color: Color, bg_color: Color, pos: Pos, width: u32, scale: f32 };
pub const DrawRect = struct { pos: Pos, width: u32, height: u32, offset_percent: f32, filled: bool, color: Color };
pub const DrawRectFloat = struct { x: f32, y: f32, width: f32, height: f32, filled: bool, color: Color };
pub const DrawFill = struct { pos: Pos, color: Color };

pub const DrawCmd = union(enum) {
    sprite: DrawSprite,
    spriteScaled: DrawSpriteScaled,
    spriteFloat: DrawSpriteFloat,
    highlightTile: DrawHighlightTile,
    outlineTile: DrawOutlineTile,
    text: DrawText,
    textFloat: DrawTextFloat,
    textJustify: DrawTextJustify,
    rect: DrawRect,
    rectFloat: DrawRectFloat,
    fill: DrawFill,

    pub fn aligned(self: *DrawCmd) bool {
        return self != .SpriteFloat and self != .TextFloat;
    }

    // NOTE(zig) I would be surprised if this worked. Instead, maybe dispatch on type and use "@field"?
    pub fn pos(self: *DrawCmd) Pos {
        switch (self) {
            .sprite, .spriteScaled, .highlightTile, .outlineTile, .text, .textJustify, .rect, .fill => |draw_cmd| {
                return draw_cmd.pos;
            },

            .spriteFloat, .textFloat, .rectFloat => |draw_cmd| {
                Pos.init(draw_cmd.x, draw_cmd.y);
            },
        }
    }
};
