const std = @import("std");
const ArrayList = std.ArrayList;

const sdl2 = @import("sdl2.zig");
const Texture = sdl2.SDL_Texture;
const Renderer = sdl2.SDL_Renderer;

const drawcmd = @import("drawcmd.zig");
const DrawCmd = drawcmd.DrawCmd;
const DrawFill = drawcmd.DrawFill;
const DrawSprite = drawcmd.DrawSprite;
const utils = @import("utils.zig");
const Rect = utils.Rect;
const Pos = utils.Pos;
const sprite = @import("sprite.zig");
const Sprite = sprite.Sprite;
const SpriteSheet = sprite.SpriteSheet;
const pnl = @import("panel.zig");
const Panel = pnl.Panel;

pub const Canvas = struct {
    panel: *Panel,
    renderer: *Renderer,
    target: *Texture,
    sprites: *Sprites,
    font_texture: *Texture,

    pub fn init(panel: *Panel, renderer: *Renderer, target: *Texture, sprites: *Sprites, font_texture: *Texture) Canvas {
        return Canvas{ .panel = panel, .renderer = renderer, .target = target, .sprites = sprites, .font_texture = font_texture };
    }
};

pub const Sprites = struct {
    texture: *Texture,
    sheets: ArrayList(SpriteSheet),

    pub fn init(texture: *Texture, sheets: ArrayList(SpriteSheet)) Sprites {
        return Sprites{ .texture = texture, .sheets = sheets };
    }
};

pub fn processDrawCmd(panel: *Panel, renderer: *Renderer, texture: *Texture, sprites: *Sprites, font_texture: *Texture, draw_cmd: *const DrawCmd) void {
    var canvas = Canvas.init(panel, renderer, texture, sprites, font_texture);
    switch (draw_cmd.*) {
        .sprite => |params| processSpriteCmd(canvas, params),

        .spriteScaled => |params| _ = params,

        .spriteFloat => |params| _ = params,

        .highlightTile => |params| _ = params,

        .outlineTile => |params| _ = params,

        .text => |params| _ = params,

        .textFloat => |params| _ = params,

        .textJustify => |params| _ = params,

        .rect => |params| _ = params,

        .rectFloat => |params| _ = params,

        .fill => |params| processFillCmd(canvas, params),
    }
}

pub fn processFillCmd(canvas: Canvas, params: DrawFill) void {
    const cell_dims = canvas.panel.cellDims();
    _ = sdl2.SDL_SetRenderDrawColor(canvas.renderer, params.color.r, params.color.g, params.color.b, params.color.a);
    var src_rect = Rect{ .x = params.pos.x * @intCast(i32, cell_dims.width), .y = params.pos.y * @intCast(i32, cell_dims.height), .w = @intCast(u32, cell_dims.width), .h = @intCast(u32, cell_dims.height) };
    var sdl2_rect = Sdl2Rect(src_rect);
    _ = sdl2.SDL_RenderFillRect(canvas.renderer, &sdl2_rect);
}

pub fn processSpriteCmd(canvas: Canvas, params: DrawSprite) void {
    const sprite_sheet = &canvas.sprites.sheets.items[params.sprite.key];
    const cell_dims = canvas.panel.cellDims();

    const pos = Pos.init(params.pos.x * @intCast(i32, cell_dims.width), params.pos.y * @intCast(i32, cell_dims.height));

    const dst_rect = Rect.init(@intCast(i32, pos.x), @intCast(i32, pos.y), @intCast(u32, cell_dims.width), @intCast(u32, cell_dims.height));

    // NOTE(error) ignoring error return.
    _ = sdl2.SDL_SetTextureBlendMode(canvas.target, sdl2.SDL_BLENDMODE_BLEND);

    const src_rect = sprite_sheet.spriteSrc(params.sprite.index);
    canvas.sprite_texture.set_color_mod(params.color.r, params.color.g, params.color.b);
    canvas.sprite_texture.set_alpha_mod(params.color.a);

    sdl2.SDL_RenderCopyEx(canvas.renderer, canvas.sprite_texture, &src_rect, &dst_rect, sprite.rotation, null, flipFlags(params.sprite));
}

//    const cell_dims = panel.cellDims();
//    const sprite_sheet = &sprites[sprite.key];
//
//    const src_rect = sprite_sheet.sprite_src(sprite.index);
//
//    const dst_width = @intCast(u32, (cell_dims._width as f32 * scale);
//    const dst_height = @intCast(u32, (cell_dims._height as f32 * scale);
//
//    const x_margin = @intCast(i32, ((cell_dims._width - dst_width) / 2));
//    const y_margin = @intCast(i32, ((cell_dims._height - dst_height) / 2));
//
//    const mut dst_x = @intCast(i32, pos.x * cell_dims._width);
//    const mut dst_y = @intCast(i32, pos.y * cell_dims._height);
//    match direction {
//        PlayerDirection::Center => {
//            dst_x += x_margin;
//            dst_y += y_margin;
//        }
//
//        PlayerDirection::Left => {
//            dst_y += y_margin;
//        }
//
//        PlayerDirection::Right => {
//            dst_x += cell_dims._width as i32 - dst_width as i32;
//            dst_y += y_margin;
//        }
//
//        PlayerDirection::Up => {
//            dst_x += x_margin;
//        }
//
//        PlayerDirection::Down => {
//            dst_x += x_margin;
//            dst_y += cell_dims._height as i32 - dst_height as i32;
//        }
//
//        PlayerDirection::DownLeft => {
//            dst_y += cell_dims._height as i32 - dst_height as i32;
//        }
//
//        PlayerDirection::DownRight => {
//            dst_x += cell_dims._width as i32 - dst_width as i32;
//            dst_y += cell_dims._height as i32 - dst_height as i32;
//        }
//
//        PlayerDirection::UpLeft => {
//            // Already in the upper left corner by default.
//        }
//
//        PlayerDirection::UpRight => {
//            dst_x += cell_dims._width as i32  - dst_width as i32;
//        }
//    }
//
//    const dst = Rect::new(dst_x,
//                        dst_y,
//                        dst_width,
//                        dst_height);
//
//    canvas.set_blend_mode(BlendMode::Blend);
//    sprite_texture.set_color_mod(color.r, color.g, color.b);
//    sprite_texture.set_alpha_mod(color.a);
//
//    canvas.copy_ex(sprite_texture,
//                   src_rect,
//                   Some(dst),
//                   sprite.rotation,
//                   None,
//                   false,
//                   false).unwrap();

pub fn flipFlags(spr: *const Sprite) sdl2.SDL_RenderFlip {
    var flags: sdl2.SDL_RenderFlip = 0;
    if (spr.flip_horiz) {
        flags |= sdl2.SDL_FLIP_HORIZONTAL;
    }

    if (spr.flip_vert) {
        flags |= sdl2.SDL_FLIP_VERTICAL;
    }
    return flags;
}

pub fn Sdl2Color(color: utils.Color) sdl2.SDL_Color {
    return sdl2.SDL_Color{ .r = color.r, .g = color.g, .b = color.b, .a = color.a };
}

pub fn Sdl2Rect(rect: Rect) sdl2.SDL_Rect {
    return sdl2.SDL_Rect{ .x = rect.x, .y = rect.y, .w = @intCast(c_int, rect.w), .h = @intCast(c_int, rect.h) };
}
