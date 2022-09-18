const std = @import("std");
const builtin = @import("builtin");

const zt = @import("zigtcl");

const utils = @import("utils.zig");
const sprite = @import("sprite.zig");
const state = @import("state.zig");
const State = state.State;
const drawcmd = @import("drawcmd.zig");
const DrawCmd = drawcmd.DrawCmd;

export fn Zigdrawcmd_Init(interp: zt.Interp) c_int {
    if (builtin.os.tag != .windows) {
        var rc = zt.tcl.Tcl_InitStubs(interp, "8.6", 0);
        std.debug.print("\nInit result {s}\n", .{rc});
    } else {
        var rc = zt.tcl.Tcl_PkgRequire(interp, "Tcl", "8.6", 0);
        std.debug.print("\nInit result {s}\n", .{rc});
    }

    //_ = zt.CreateObjCommand(interp, "zigtcl::zigcreate", Hello_ZigTclCmd) catch return zt.tcl.TCL_ERROR;

    //zt.WrapFunction(test_function, "zigtcl::zig_function", interp) catch return zt.tcl.TCL_ERROR;

    _ = zt.RegisterStruct(State, "State", "drawcmd", interp);
    _ = zt.RegisterStruct(sprite.Sprite, "Sprite", "drawcmd", interp);
    _ = zt.RegisterStruct(utils.Color, "Color", "drawcmd", interp);
    _ = zt.RegisterStruct(utils.Pos, "Pos", "drawcmd", interp);
    _ = zt.RegisterUnion(DrawCmd, "DrawCmd", "drawcmd", interp);

    return zt.tcl.Tcl_PkgProvide(interp, "drawcmd", "0.1.0");
}
