const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const State = @import("state.zig").State;

const window_width: c_int = 800;
const window_height: c_int = 600;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var state = try State.init(window_width, window_height, arena.allocator());
    defer state.deinit();

    var quit = false;
    while (!quit) {
        quit = state.handle_input();

        try state.render();

        state.wait_for_frame();
    }
}
