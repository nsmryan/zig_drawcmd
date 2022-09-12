const std = @import("std");
const ArrayList = std.ArrayList;
const assert = std.debug.assert;

const sdl2 = @import("sdl2.zig");
const Texture = sdl2.SDL_Texture;
const Renderer = sdl2.SDL_Renderer;

const drawcmd = @import("drawcmd.zig");
const DrawCmd = drawcmd.DrawCmd;
const DrawFill = drawcmd.DrawFill;
const DrawRect = drawcmd.DrawRect;
const DrawSprite = drawcmd.DrawSprite;
const DrawRectFloat = drawcmd.DrawRectFloat;
const DrawOutlineTile = drawcmd.DrawOutlineTile;
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

        .outlineTile => |params| _ = processOutlineTile(canvas, params),

        .text => |params| _ = params,

        .textFloat => |params| _ = params,

        .textJustify => |params| _ = params,

        .rect => |params| _ = processRectCmd(canvas, params),

        .rectFloat => |params| _ = processRectFloatCmd(canvas, params),

        .fill => |params| processFillCmd(canvas, params),
    }
}

pub fn processOutlineTile(canvas: Canvas, params: DrawOutlineTile) void {
    const cell_dims = canvas.panel.cellDims();

    _ = sdl2.SDL_SetTextureBlendMode(canvas.target, sdl2.SDL_BLENDMODE_BLEND);
    _ = sdl2.SDL_SetRenderDrawColor(canvas.renderer, params.color.r, params.color.g, params.color.b, params.color.a);

    const rect = Rect.init(
        params.pos.x * @intCast(i32, cell_dims.width) + 1,
        params.pos.y * @intCast(i32, cell_dims.height) + 1,
        @intCast(u32, cell_dims.width),
        @intCast(u32, cell_dims.height),
    );

    _ = sdl2.SDL_RenderDrawRect(canvas.renderer, &Sdl2Rect(rect));
}

pub fn processFillCmd(canvas: Canvas, params: DrawFill) void {
    const cell_dims = canvas.panel.cellDims();
    _ = sdl2.SDL_SetRenderDrawColor(canvas.renderer, params.color.r, params.color.g, params.color.b, params.color.a);
    var src_rect = Rect{ .x = params.pos.x * @intCast(i32, cell_dims.width), .y = params.pos.y * @intCast(i32, cell_dims.height), .w = @intCast(u32, cell_dims.width), .h = @intCast(u32, cell_dims.height) };
    var sdl2_rect = Sdl2Rect(src_rect);
    _ = sdl2.SDL_RenderFillRect(canvas.renderer, &sdl2_rect);
}

pub fn processRectCmd(canvas: Canvas, params: DrawRect) void {
    assert(params.offset_percent < 1.0);

    const cell_dims = canvas.panel.cellDims();

    _ = sdl2.SDL_SetRenderDrawColor(canvas.renderer, params.color.r, params.color.g, params.color.b, params.color.a);

    const offset_x = @floatToInt(i32, @intToFloat(f32, cell_dims.width) * params.offset_percent);
    const x: i32 = @intCast(i32, cell_dims.width) * params.pos.x + @intCast(i32, offset_x);

    const offset_y = @floatToInt(i32, @intToFloat(f32, cell_dims.height) * params.offset_percent);
    const y: i32 = @intCast(i32, cell_dims.height) * params.pos.y + @intCast(i32, offset_y);

    const width = @intCast(u32, cell_dims.width * params.width - (2 * @intCast(u32, offset_x)));
    const height = @intCast(u32, cell_dims.height * params.height - (2 * @intCast(u32, offset_y)));

    const size = @intCast(u32, (canvas.panel.num_pixels.width / canvas.panel.cells.width) / 10);
    if (params.filled) {
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.init(x, y, width, height)));
    } else {
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.init(x, y, size, height)));
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.init(x, y, width, size)));
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.init(x + @intCast(i32, width), y, size, height + size)));
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.init(x, y + @intCast(i32, height), width + size, size)));
    }
}

pub fn processRectFloatCmd(canvas: Canvas, params: DrawRectFloat) void {
    const cell_dims = canvas.panel.cellDims();

    _ = sdl2.SDL_SetRenderDrawColor(canvas.renderer, params.color.r, params.color.g, params.color.b, params.color.a);

    const x_offset = @floatToInt(i32, params.x * @intToFloat(f32, cell_dims.width));
    const y_offset = @floatToInt(i32, params.y * @intToFloat(f32, cell_dims.height));

    const width = @floatToInt(u32, params.width * @intToFloat(f32, cell_dims.width));
    const height = @floatToInt(u32, params.height * @intToFloat(f32, cell_dims.height));

    const size = @intCast(u32, (canvas.panel.num_pixels.width / canvas.panel.cells.width) / 5);
    if (params.filled) {
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.init(x_offset, y_offset, width, height)));
    } else {
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.init(x_offset, y_offset, size, height)));
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.init(x_offset, y_offset, width + size, size)));
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.init(x_offset + @intCast(i32, width), y_offset, size, height)));
        _ = sdl2.SDL_RenderFillRect(canvas.renderer, &Sdl2Rect(Rect.init(x_offset, y_offset + @intCast(i32, height) - @intCast(i32, size), width + size, size)));
    }
}

pub fn processSpriteCmd(canvas: Canvas, params: DrawSprite) void {
    const sprite_sheet = &canvas.sprites.sheets.items[params.sprite.key];
    const cell_dims = canvas.panel.cellDims();

    const pos = Pos.init(params.pos.x * @intCast(i32, cell_dims.width), params.pos.y * @intCast(i32, cell_dims.height));

    const dst_rect = Rect.init(@intCast(i32, pos.x), @intCast(i32, pos.y), @intCast(u32, cell_dims.width), @intCast(u32, cell_dims.height));

    // NOTE(error) ignoring error return.
    _ = sdl2.SDL_SetTextureBlendMode(canvas.target, sdl2.SDL_BLENDMODE_BLEND);

    const src_rect = sprite_sheet.spriteSrc(params.sprite.index);
    // NOTE(error) ignoring error return.
    _ = sdl2.SDL_SetTextureColorMod(canvas.sprites.texture, params.color.r, params.color.g, params.color.b);
    // NOTE(error) ignoring error return.
    _ = sdl2.SDL_SetTextureAlphaMod(canvas.sprites.texture, params.color.a);

    // NOTE(error) ignoring error return.
    _ = sdl2.SDL_RenderCopyEx(
        canvas.renderer,
        canvas.sprites.texture,
        &Sdl2Rect(src_rect),
        &Sdl2Rect(dst_rect),
        params.sprite.rotation,
        null,
        flipFlags(&params.sprite),
    );
}

pub fn flipFlags(spr: *const Sprite) sdl2.SDL_RendererFlip {
    var flags: sdl2.SDL_RendererFlip = 0;
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
