const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const sdl2 = @import("sdl2.zig");

const State = @import("state.zig").State;
const drawcmd = @import("drawcmd.zig");
const sprite = @import("sprite.zig");
const DrawCmd = drawcmd.DrawCmd;
const drawing = @import("drawing.zig");
const utils = @import("utils.zig");
const Direction = utils.Direction;
const Pos = utils.Pos;
const Color = utils.Color;

const window_width: c_int = 800;
const window_height: c_int = 600;

pub fn main() !void {
    var state = try State.init(window_width, window_height);
    defer state.deinit();

    var quit = false;
    while (!quit) {
        quit = state.handle_input();

        try state.render();

        state.wait_for_frame();
    }
}

pub fn render(state: *State) !void {
    _ = sdl2.SDL_SetRenderDrawColor(state.renderer, 0, 0, 0, sdl2.SDL_ALPHA_OPAQUE);
    _ = sdl2.SDL_RenderClear(state.renderer);

    const fill_cmd = DrawCmd.fill(Pos.init(21, 20), Color.init(255, 0, 0, 255));
    drawing.processDrawCmd(&state.panel, state.renderer, state.screen_texture, &state.sprites, state.ascii_texture, &fill_cmd);

    const rect_cmd = DrawCmd.rect(Pos.init(20, 20), 2, 2, 0.2, false, Color.init(0, 255, 0, 255));
    drawing.processDrawCmd(&state.panel, state.renderer, state.screen_texture, &state.sprites, state.ascii_texture, &rect_cmd);

    const rect_float_cmd = DrawCmd.rectFloat(20, 20, 5, 5, false, Color.init(0, 255, 0, 255));
    drawing.processDrawCmd(&state.panel, state.renderer, state.screen_texture, &state.sprites, state.ascii_texture, &rect_float_cmd);

    const outline_tile_cmd = DrawCmd.outlineTile(Pos.init(10, 10), Color.init(0, 255, 0, 255));
    drawing.processDrawCmd(&state.panel, state.renderer, state.screen_texture, &state.sprites, state.ascii_texture, &outline_tile_cmd);

    const outline_tile_cmd_2 = DrawCmd.outlineTile(Pos.init(11, 10), Color.init(0, 255, 0, 255));
    drawing.processDrawCmd(&state.panel, state.renderer, state.screen_texture, &state.sprites, state.ascii_texture, &outline_tile_cmd_2);

    const highlight_tile_cmd = DrawCmd.highlightTile(Pos.init(11, 11), Color.init(0, 255, 0, 128));
    drawing.processDrawCmd(&state.panel, state.renderer, state.screen_texture, &state.sprites, state.ascii_texture, &highlight_tile_cmd);

    const sprite_key = try sprite.lookupSpritekey(&state.sprites.sheets, "player_standing_right"[0..]);
    const spr = sprite.Sprite.init(0, sprite_key);
    const sprite_cmd = DrawCmd.sprite(spr, Color.init(255, 255, 255, 255), Pos.init(20, 20));
    drawing.processDrawCmd(&state.panel, state.renderer, state.screen_texture, &state.sprites, state.ascii_texture, &sprite_cmd);

    const sprite_scaled_cmd = DrawCmd.spriteScaled(spr, 0.7, Direction.downRight, Color.init(255, 255, 255, 255), Pos.init(10, 10));
    drawing.processDrawCmd(&state.panel, state.renderer, state.screen_texture, &state.sprites, state.ascii_texture, &sprite_scaled_cmd);

    const sprite_float_cmd = DrawCmd.spriteFloat(spr, Color.init(255, 255, 255, 255), 15.0, 15.0, 2.0, 2.0);
    drawing.processDrawCmd(&state.panel, state.renderer, state.screen_texture, &state.sprites, state.ascii_texture, &sprite_float_cmd);

    const text_cmd = DrawCmd.text("hello"[0..], Pos.init(8, 8), Color.init(0, 255, 0, 128), 1.0);
    drawing.processDrawCmd(&state.panel, state.renderer, state.screen_texture, &state.sprites, state.ascii_texture, &text_cmd);

    const text_float_cmd = DrawCmd.textFloat("hello"[0..], 9.5, 9.5, Color.init(0, 255, 0, 128), 1.0);
    drawing.processDrawCmd(&state.panel, state.renderer, state.screen_texture, &state.sprites, state.ascii_texture, &text_float_cmd);

    const text_justify_center_cmd = DrawCmd.textJustify("center"[0..], drawcmd.Justify.center, Pos.init(0, 0), Color.init(0, 255, 0, 128), 40, 1.0);
    drawing.processDrawCmd(&state.panel, state.renderer, state.screen_texture, &state.sprites, state.ascii_texture, &text_justify_center_cmd);

    const text_justify_left_cmd = DrawCmd.textJustify("left"[0..], drawcmd.Justify.left, Pos.init(0, 0), Color.init(0, 255, 0, 128), 40, 1.0);
    drawing.processDrawCmd(&state.panel, state.renderer, state.screen_texture, &state.sprites, state.ascii_texture, &text_justify_left_cmd);

    const text_justify_right_cmd = DrawCmd.textJustify("right"[0..], drawcmd.Justify.right, Pos.init(0, 0), Color.init(0, 255, 0, 128), 40, 1.0);
    drawing.processDrawCmd(&state.panel, state.renderer, state.screen_texture, &state.sprites, state.ascii_texture, &text_justify_right_cmd);

    sdl2.SDL_RenderPresent(state.renderer);
}

pub fn wait_for_frame(state: *State) void {
    _ = state;
    sdl2.SDL_Delay(17);
}

pub fn handle_input(state: *State) bool {
    _ = state;

    var quit = false;

    var event: sdl2.SDL_Event = undefined;
    while (sdl2.SDL_PollEvent(&event) != 0) {
        switch (event.@"type") {
            sdl2.SDL_QUIT => {
                quit = true;
            },

            // SDL_Scancode scancode;      /**< SDL physical key code - see ::SDL_Scancode for details */
            // SDL_Keycode sym;            /**< SDL virtual key code - see ::SDL_Keycode for details */
            // Uint16 mod;                 /**< current key modifiers */
            sdl2.SDL_KEYDOWN => {
                const code: i32 = event.key.keysym.sym;
                const key: sdl2.SDL_KeyCode = @intCast(c_uint, code);

                //const a_code = sdl2.SDLK_a;
                //const z_code = sdl2.SDLK_z;

                if (key == sdl2.SDLK_RETURN) {
                    sdl2.SDL_Log("Pressed enter");
                } else if (key == sdl2.SDLK_ESCAPE) {
                    quit = true;
                } else {
                    sdl2.SDL_Log("Pressed: %c", key);
                }
            },

            sdl2.SDL_KEYUP => {},

            sdl2.SDL_MOUSEMOTION => {
                //state.state.mouse = sdl2.SDL_Point{ .x = event.motion.x, .y = event.motion.y };
            },

            sdl2.SDL_MOUSEBUTTONDOWN => {},

            sdl2.SDL_MOUSEBUTTONUP => {},

            sdl2.SDL_MOUSEWHEEL => {},

            // just for fun...
            sdl2.SDL_DROPFILE => {
                sdl2.SDL_Log("Dropped file '%s'", event.drop.file);
            },
            sdl2.SDL_DROPTEXT => {
                sdl2.SDL_Log("Dropped text '%s'", event.drop.file);
            },
            sdl2.SDL_DROPBEGIN => {
                sdl2.SDL_Log("Drop start");
            },
            sdl2.SDL_DROPCOMPLETE => {
                sdl2.SDL_Log("Drop done");
            },

            // could be used for clock tick
            sdl2.SDL_USEREVENT => {},

            else => {},
        }
    }

    return quit;
}
