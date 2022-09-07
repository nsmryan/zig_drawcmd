const sdl2 = @import("sdl2.zig");
const Texture = sdl2.Texture;
const drawcmd = @import("drawcmd.zig");
const utils = @import("utils.zig");
const Rect = utils.Rect;

pub fn flipFlags(sprite: *const Sprite) sdl2.SDL_RenderFlip {
    var flags: sdl2.SDL_RenderFlip = 0;
    if (sprite.flip_horiz) {
        flags |= sdl2.SDL_FLIP_HORIZONTAL;
    }

    if (sprite.flip_vert) {
        flags |= sdl2.SDL_FLIP_VERTICAL;
    }
    return flags;
}

pub fn Sdl2Color(color: utils.Color) sdl2.SDL_Color {
    return sdl2.SDL_Color{ .r = color.r, .g = color.g, .b = color.b, .a = color.a };
}

pub fn processDrawCmd(panel: *const Panel, texture: Texture, sprite_texture: Texture, font_texture: Texture, drawcmd: *const DrawCmd) void {
    switch (drawcmd) {
        .sprite => |params| processSpriteCmd(panel, texture, sprite_texture, font_texture, params),

        .spriteScaled => |params| {},

        .spriteFloat => |params| {},

        .highlightTile => |params| {},

        .outlineTile => |params| {},

        .text => |params| {},

        .textFloat => |params| {},

        .textJustify => |params| {},

        .rect => |params| {},

        .rectFloat => |params| {},

        .fill => |params| processFillCmd(panel, texture, sprite_texture, font_texture, params),
    }
}

pub fn processFillCmd(panel: *const Panel, texture: Texture, sprite_texture: Texture, font_texture: Texture, params: *const DrawFill) void {
    const cell_dims = panel.cell_dims();
    texture.set_draw_color(Sdl2Color(params.color));
    sdl2.SDL_RenderFillRect(renderer, Rect{ .x = @intCast(i32, pos.x * cell_dims.width), .y = @intCast(i32, pos.y * cell_dims.height), .w = cell_dims.width, .h = cell_dims.height });
}

pub fn processSpriteCmd(panel: *const Panel, texture: Texture, sprite_texture: Texture, font_texture: Texture, params: *const DrawSprite) void {
    const sprite_sheet = &sprites[sprite.key];
    const cell_dims = panel.cell_dims();

    const pos = Pos.init(@intCast(i32, params.pos.x * cell_dims.width), @intCast(i32, params.pos.y * cell_dims.height));

    const dst_rect = Rect.init(@intCast(i32, pos.x), @intCast(i32, pos.y), @intCast(u32, cell_dims.width), @intCast(u32, cell_dims.height));

    sdl2.SDL_SetTextureBlendMode(texture, sdl2.SDL2_BlendMode.Blend);

    const src_rect = sprite_sheet.sprite_src(sprite.index);
    sprite_texture.set_color_mod(params.color.r, params.color.g, params.color.b);
    sprite_texture.set_alpha_mod(params.color.a);

    sdl2.SDL_RenderCopyEx(renderer, sprite_texture, &src_rect, &dst_rect, sprite.rotation, null, flipFlags(params.sprite));
}

//    const cell_dims = panel.cell_dims();
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
