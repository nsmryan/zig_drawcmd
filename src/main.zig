const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
    @cInclude("SDL2/SDL_image.h");
    @cInclude("layout.h");
});
const assert = @import("std").debug.assert;
const mem = @import("std").mem;
const fs = @import("std").fs;

const window_width: c_int = 800;
const window_height: c_int = 600;

const State = struct {
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,
    font: *c.TTF_Font,

    fn create() !State {
        if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        _ = c.SDL_ShowCursor(0);

        if (c.TTF_Init() == -1) {
            c.SDL_Log("Unable to initialize SDL_ttf: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        const window = c.SDL_CreateWindow("DrawCmd", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, window_width, window_height, c.SDL_WINDOW_OPENGL) orelse
            {
            c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        const renderer = c.SDL_CreateRenderer(window, -1, 0) orelse {
            c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        const font = c.TTF_OpenFont("data/Monoid.ttf", 20) orelse {
            c.SDL_Log("Unable to create font from tff: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        var game: State = State{ .window = window, .renderer = renderer, .font = font };
        return game;
    }

    fn render_text(self: *State, text: []const u8, color: c.SDL_Color) !*c.SDL_Texture {
        const c_text = @ptrCast([*c]const u8, text);
        const text_surface = c.TTF_RenderText_Solid(self.font, c_text, color) orelse {
            c.SDL_Log("Unable to create text from font: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        const texture = c.SDL_CreateTextureFromSurface(self.renderer, text_surface) orelse {
            c.SDL_Log("Unable to create texture from surface: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        return texture;
    }

    fn destroy(self: *State) void {
        c.SDL_DestroyRenderer(self.renderer);
        c.SDL_DestroyWindow(self.window);
        c.SDL_Quit();
    }

    fn render(self: *State) !void {
        c.SDL_RenderPresent(self.renderer);
        _ = c.SDL_SetRenderDrawColor(self.renderer, 0, 0, 0, 0);
        _ = c.SDL_RenderClear(self.renderer);
    }

    fn wait_for_frame(self: *State) void {
        _ = self;
        c.SDL_Delay(17);
    }

    fn handle_input(self: *State) bool {
        _ = self;

        var quit = false;

        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.@"type") {
                c.SDL_QUIT => {
                    quit = true;
                },

                // SDL_Scancode scancode;      /**< SDL physical key code - see ::SDL_Scancode for details */
                // SDL_Keycode sym;            /**< SDL virtual key code - see ::SDL_Keycode for details */
                // Uint16 mod;                 /**< current key modifiers */
                c.SDL_KEYDOWN => {
                    const code: i32 = event.key.keysym.sym;
                    const key: c.SDL_KeyCode = @intCast(c_uint, code);

                    //const a_code = c.SDLK_a;
                    //const z_code = c.SDLK_z;

                    if (key == c.SDLK_RETURN) {
                        c.SDL_Log("Pressed enter");
                    } else if (key == c.SDLK_ESCAPE) {
                        quit = true;
                    } else {
                        c.SDL_Log("Pressed: %c", key);
                    }
                },

                c.SDL_KEYUP => {},

                c.SDL_MOUSEMOTION => {
                    //self.state.mouse = c.SDL_Point{ .x = event.motion.x, .y = event.motion.y };
                },

                c.SDL_MOUSEBUTTONDOWN => {},

                c.SDL_MOUSEBUTTONUP => {},

                c.SDL_MOUSEWHEEL => {},

                // just for fun...
                c.SDL_DROPFILE => {
                    c.SDL_Log("Dropped file '%s'", event.drop.file);
                },
                c.SDL_DROPTEXT => {
                    c.SDL_Log("Dropped text '%s'", event.drop.file);
                },
                c.SDL_DROPBEGIN => {
                    c.SDL_Log("Drop start");
                },
                c.SDL_DROPCOMPLETE => {
                    c.SDL_Log("Drop done");
                },

                // could be used for clock tick
                c.SDL_USEREVENT => {},

                else => {},
            }
        }

        return quit;
    }
};

pub fn main() !void {
    var game = try State.create();
    defer game.destroy();

    var quit = false;
    while (!quit) {
        quit = game.handle_input();

        try game.render();

        game.wait_for_frame();
    }
}
