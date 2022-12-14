const std = @import("std");
const ArrayList = std.ArrayList;
const assert = std.debug.assert;
const mem = std.mem;
const fs = std.fs;
const Allocator = mem.Allocator;

const sdl2 = @import("sdl2.zig");
const Texture = sdl2.SDL_Texture;
const Renderer = sdl2.SDL_Renderer;
const Font = sdl2.TTF_Font;
const Window = sdl2.SDL_Window;

const drawcmd = @import("drawcmd.zig");
const DrawCmd = drawcmd.DrawCmd;
const panel = @import("panel.zig");
const Panel = panel.Panel;
const area = @import("area.zig");
const Dims = area.Dims;
const utils = @import("utils.zig");
const Direction = utils.Direction;
const sprite = @import("sprite.zig");
const SpriteSheet = sprite.SpriteSheet;
const drawing = @import("drawing.zig");
const Sprites = drawing.Sprites;
const Pos = utils.Pos;
const Color = utils.Color;

pub const State = struct {
    window: *Window,
    renderer: *Renderer,
    font: *Font,
    ascii_texture: drawing.AsciiTexture,
    screen_texture: *Texture,
    sprites: Sprites,
    panel: Panel,

    drawcmds: ArrayList(DrawCmd),
    arena: std.heap.ArenaAllocator,

    pub fn init(window_width: c_int, window_height: c_int) !State {
        // Create the allocator internally for a simpler TCL interface.
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        var allocator = arena.allocator();

        var drawcmds = ArrayList(DrawCmd).init(allocator);

        if (sdl2.SDL_Init(sdl2.SDL_INIT_VIDEO) != 0) {
            sdl2.SDL_Log("Unable to initialize SDL: %s", sdl2.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        _ = sdl2.SDL_ShowCursor(0);

        if (sdl2.TTF_Init() == -1) {
            sdl2.SDL_Log("Unable to initialize SDL_ttf: %s", sdl2.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        const window = sdl2.SDL_CreateWindow("DrawCmd", sdl2.SDL_WINDOWPOS_UNDEFINED, sdl2.SDL_WINDOWPOS_UNDEFINED, window_width, window_height, sdl2.SDL_WINDOW_OPENGL) orelse
            {
            sdl2.SDL_Log("Unable to create window: %s", sdl2.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        const renderer = sdl2.SDL_CreateRenderer(window, -1, sdl2.SDL_RENDERER_ACCELERATED) orelse {
            sdl2.SDL_Log("Unable to create renderer: %s", sdl2.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        const screen_texture = sdl2.SDL_CreateTexture(renderer, sdl2.SDL_PIXELFORMAT_RGBA8888, sdl2.SDL_TEXTUREACCESS_TARGET, window_width, window_height) orelse {
            sdl2.SDL_Log("Unable to create screen texture: %s", sdl2.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        // NOTE default to rendering to the screen. If we move to multiple targets, we may use this as a final
        // back buffer so we can save/restore/etc the screen buffer.
        //if (sdl2.SDL_SetRenderTarget(renderer, screen_texture) != 0) {
        //    sdl2.SDL_Log("Unable to set render target: %s", sdl2.SDL_GetError());
        //    return error.SDLInitializationFailed;
        //}

        const sprite_surface = sdl2.IMG_Load("data/spriteAtlas.png") orelse {
            sdl2.SDL_Log("Unable to load sprite image: %s", sdl2.SDL_GetError());
            return error.SDLInitializationFailed;
        };
        defer sdl2.SDL_FreeSurface(sprite_surface);

        const sprite_texture = sdl2.SDL_CreateTextureFromSurface(renderer, sprite_surface) orelse {
            sdl2.SDL_Log("Unable to create sprite texture: %s", sdl2.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        var sheets = try sprite.parseAtlasFile("data/spriteAtlas.txt"[0..], allocator);
        var sprites = Sprites.init(sprite_texture, sheets);

        const font = sdl2.TTF_OpenFont("data/Inconsolata-Bold.ttf", 20) orelse {
            sdl2.SDL_Log("Unable to create font from tff: %s", sdl2.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        const ascii_texture = try drawing.AsciiTexture.renderAsciiCharacters(renderer, font);

        const num_pixels = Dims.init(@intCast(usize, window_width), @intCast(usize, window_height));
        const cell_dims = Dims.init(40, 30);
        const screen_panel = Panel.init(num_pixels, cell_dims);

        var game: State = State{
            .window = window,
            .renderer = renderer,
            .font = font,
            .ascii_texture = ascii_texture,
            .panel = screen_panel,
            .sprites = sprites,
            .screen_texture = screen_texture,
            .drawcmds = drawcmds,
            .arena = arena,
        };
        return game;
    }

    pub fn push(self: *State, cmd: DrawCmd) !void {
        std.debug.print("state {}\n", .{self});
        std.debug.print("push {}\n", .{cmd});
        try self.drawcmds.append(cmd);
        std.debug.print("pushed\n", .{});
    }

    pub fn present(self: *State) void {
        std.debug.print("clear\n", .{});
        _ = sdl2.SDL_SetRenderDrawColor(self.renderer, 0, 0, 0, sdl2.SDL_ALPHA_OPAQUE);
        _ = sdl2.SDL_RenderClear(self.renderer);

        std.debug.print("cmds\n", .{});
        for (self.drawcmds.items) |cmd| {
            drawing.processDrawCmd(&self.panel, self.renderer, self.screen_texture, &self.sprites, self.ascii_texture, &cmd);
        }

        std.debug.print("present\n", .{});
        sdl2.SDL_RenderPresent(self.renderer);

        std.debug.print("remove\n", .{});
        self.drawcmds.clearRetainingCapacity();

        std.debug.print("done\n", .{});
    }

    //fn renderText(self: *State, text: []const u8, color: sdl2.SDL_Color) !*Texture {
    //    const c_text = @ptrCast([*c]const u8, text);
    //    const text_surface = sdl2.TTF_RenderText_Blended(self.font, c_text, color) orelse {
    //        sdl2.SDL_Log("Unable to create text from font: %s", sdl2.SDL_GetError());
    //        return error.SDLInitializationFailed;
    //    };

    //    const texture = sdl2.SDL_CreateTextureFromSurface(self.renderer, text_surface) orelse {
    //        sdl2.SDL_Log("Unable to create texture from surface: %s", sdl2.SDL_GetError());
    //        return error.SDLInitializationFailed;
    //    };

    //    return texture;
    //}

    pub fn deinit(self: *State) void {
        self.ascii_texture.deinit();
        sdl2.SDL_DestroyTexture(self.screen_texture);
        sdl2.TTF_CloseFont(self.font);
        sdl2.SDL_DestroyRenderer(self.renderer);
        sdl2.SDL_DestroyWindow(self.window);
        sdl2.SDL_Quit();
        self.arena.deinit();
    }

    pub fn render(self: *State) !void {
        _ = sdl2.SDL_SetRenderDrawColor(self.renderer, 0, 0, 0, sdl2.SDL_ALPHA_OPAQUE);
        _ = sdl2.SDL_RenderClear(self.renderer);

        const fill_cmd = DrawCmd.fill(Pos.init(21, 20), Color.init(255, 0, 0, 255));
        drawing.processDrawCmd(&self.panel, self.renderer, self.screen_texture, &self.sprites, self.ascii_texture, &fill_cmd);

        const rect_cmd = DrawCmd.rect(Pos.init(20, 20), 2, 2, 0.2, false, Color.init(0, 255, 0, 255));
        drawing.processDrawCmd(&self.panel, self.renderer, self.screen_texture, &self.sprites, self.ascii_texture, &rect_cmd);

        const rect_float_cmd = DrawCmd.rectFloat(20, 20, 5, 5, false, Color.init(0, 255, 0, 255));
        drawing.processDrawCmd(&self.panel, self.renderer, self.screen_texture, &self.sprites, self.ascii_texture, &rect_float_cmd);

        const outline_tile_cmd = DrawCmd.outlineTile(Pos.init(10, 10), Color.init(0, 255, 0, 255));
        drawing.processDrawCmd(&self.panel, self.renderer, self.screen_texture, &self.sprites, self.ascii_texture, &outline_tile_cmd);

        const outline_tile_cmd_2 = DrawCmd.outlineTile(Pos.init(11, 10), Color.init(0, 255, 0, 255));
        drawing.processDrawCmd(&self.panel, self.renderer, self.screen_texture, &self.sprites, self.ascii_texture, &outline_tile_cmd_2);

        const highlight_tile_cmd = DrawCmd.highlightTile(Pos.init(11, 11), Color.init(0, 255, 0, 128));
        drawing.processDrawCmd(&self.panel, self.renderer, self.screen_texture, &self.sprites, self.ascii_texture, &highlight_tile_cmd);

        const sprite_key = try sprite.lookupSpritekey(&self.sprites.sheets, "player_standing_right"[0..]);
        const spr = sprite.Sprite.init(0, sprite_key);
        const sprite_cmd = DrawCmd.sprite(spr, Color.init(255, 255, 255, 255), Pos.init(20, 20));
        drawing.processDrawCmd(&self.panel, self.renderer, self.screen_texture, &self.sprites, self.ascii_texture, &sprite_cmd);

        const sprite_scaled_cmd = DrawCmd.spriteScaled(spr, 0.7, Direction.downRight, Color.init(255, 255, 255, 255), Pos.init(10, 10));
        drawing.processDrawCmd(&self.panel, self.renderer, self.screen_texture, &self.sprites, self.ascii_texture, &sprite_scaled_cmd);

        const sprite_float_cmd = DrawCmd.spriteFloat(spr, Color.init(255, 255, 255, 255), 15.0, 15.0, 2.0, 2.0);
        drawing.processDrawCmd(&self.panel, self.renderer, self.screen_texture, &self.sprites, self.ascii_texture, &sprite_float_cmd);

        const text_cmd = DrawCmd.text("hello"[0..], Pos.init(8, 8), Color.init(0, 255, 0, 128), 1.0);
        drawing.processDrawCmd(&self.panel, self.renderer, self.screen_texture, &self.sprites, self.ascii_texture, &text_cmd);

        const text_float_cmd = DrawCmd.textFloat("hello"[0..], 9.5, 9.5, Color.init(0, 255, 0, 128), 1.0);
        drawing.processDrawCmd(&self.panel, self.renderer, self.screen_texture, &self.sprites, self.ascii_texture, &text_float_cmd);

        const text_justify_center_cmd = DrawCmd.textJustify("center"[0..], drawcmd.Justify.center, Pos.init(0, 0), Color.init(0, 255, 0, 128), 40, 1.0);
        drawing.processDrawCmd(&self.panel, self.renderer, self.screen_texture, &self.sprites, self.ascii_texture, &text_justify_center_cmd);

        const text_justify_left_cmd = DrawCmd.textJustify("left"[0..], drawcmd.Justify.left, Pos.init(0, 0), Color.init(0, 255, 0, 128), 40, 1.0);
        drawing.processDrawCmd(&self.panel, self.renderer, self.screen_texture, &self.sprites, self.ascii_texture, &text_justify_left_cmd);

        const text_justify_right_cmd = DrawCmd.textJustify("right"[0..], drawcmd.Justify.right, Pos.init(0, 0), Color.init(0, 255, 0, 128), 40, 1.0);
        drawing.processDrawCmd(&self.panel, self.renderer, self.screen_texture, &self.sprites, self.ascii_texture, &text_justify_right_cmd);

        sdl2.SDL_RenderPresent(self.renderer);
    }

    pub fn wait_for_frame(self: *State) void {
        _ = self;
        sdl2.SDL_Delay(17);
    }

    pub fn handle_input(self: *State) bool {
        _ = self;

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
                    //self.state.mouse = sdl2.SDL_Point{ .x = event.motion.x, .y = event.motion.y };
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

    pub fn lookupSpritekey(self: *State, name: []const u8) !sprite.SpriteKey {
        return sprite.lookupSpritekey(&self.sprites.sheets, name);
    }

    pub fn numSprites(self: *State, name: []const u8) !usize {
        const key = try sprite.lookupSpritekey(&self.sprites.sheets, name);
        return self.sprites.sheets.items[key].num_sprites;
    }
};
