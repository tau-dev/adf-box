const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // _ = b.addUserInputOption("rpath", "${ORIGIN}") catch unreachable;

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = .ReleaseFast; //b.standardReleaseOptions();

    const exe = b.addExecutable("adf-box", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.setLibCFile("libc.txt");
    exe.addLibPath("V-EZ/Bin/x86_64/");
    exe.addPackagePath("zalgebra", "zalgebra/src/main.zig");
    exe.addBuildOption([]const u8, "rpath", "${ORIGIN}");

    var d = std.fs.cwd().openDir("src/shaders", .{ .access_sub_paths = false, .iterate = true }) catch unreachable;
    defer d.close();
    var it = d.iterate();
    while (it.next() catch unreachable) |entry| {
        if (entry.kind == .File) {
            var source = std.fs.path.join(b.allocator, &[_][]const u8{ "src/shaders", entry.name }) catch unreachable;
            var compile = std.fs.path.join(b.allocator, &[_][]const u8{ "shaders-bin", entry.name }) catch unreachable;
            var dest = std.fs.path.join(b.allocator, &[_][]const u8{ "shaders", entry.name }) catch unreachable;

            var compileShader = b.addSystemCommand(&[_][]const u8{ "glslangValidator", "-V", source, "-o", compile }); //"-g", "-Od",
            var installShader = b.addInstallFileWithDir(compile, .Bin, dest);
            installShader.step.dependOn(&compileShader.step);
            exe.step.dependOn(&installShader.step);
        }
    }

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("VEZ");
    exe.linkSystemLibrary("glfw");
    exe.linkSystemLibrary("vulkan");
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
