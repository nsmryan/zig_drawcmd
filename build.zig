const Builder = @import("std").build.Builder;
const builtin = @import("builtin");

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("game", "src/main.zig");

    exe.setBuildMode(mode);
    exe.addIncludeDir("deps/SDL2");
    exe.addLibPath("lib");
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_ttf");
    exe.linkSystemLibrary("SDL2_image");
    exe.linkSystemLibrary("c");

    b.default_step.dependOn(&exe.step);

    b.installArtifact(exe);

    const lib = b.addSharedLibrary("zigdrawcmd", "src/zig_drawcmd.zig", b.version(0, 1, 0));
    lib.setBuildMode(mode);
    lib.linkLibC();
    lib.addLibPath("/usr/lib");
    lib.linkSystemLibrary("SDL2");
    lib.linkSystemLibrary("SDL2_ttf");
    lib.linkSystemLibrary("SDL2_image");
    lib.addIncludeDir("/usr/include");
    lib.linkSystemLibraryName("tclstub8.6");
    lib.addPackagePath("zigtcl", "deps/zig_tcl/src/zigtcl.zig");

    lib.install();

    const run = b.step("run", "Run the game");
    const run_cmd = exe.run();
    run.dependOn(&run_cmd.step);
}
