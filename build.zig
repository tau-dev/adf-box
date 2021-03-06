const std = @import("std");
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;

fn join(builder: *Builder, a: []const u8, b: []const u8) []const u8 {
    return std.fs.path.join(builder.allocator, &[_][]const u8{ a, b }) catch unreachable;
}

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = .ReleaseFast; //b.standardReleaseOptions();

    const exe = b.addExecutable("adf-box", "src/main.zig");

    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackagePath("zalgebra", "zalgebra/src/main.zig");

    var d = std.fs.cwd().openDir("src/shaders", .{ .access_sub_paths = false, .iterate = true }) catch unreachable;
    std.fs.cwd().makeDir("src/shaders/bin") catch |err| switch(err) {
        error.PathAlreadyExists => {},
        else => unreachable,
    };
    defer d.close();
    var it = d.iterate();
    while (it.next() catch unreachable) |entry| {
        if (entry.kind == .File) {
            var source = join(b, "src/shaders", entry.name);
            var compiled = join(b, "src/shaders/bin", entry.name);
            var dest = join(b, "shaders", entry.name);

            var installShader = b.addInstallFileWithDir(compiled, .Bin, dest);
            exe.step.dependOn(&installShader.step);

            if (needs_update(source, compiled)) {
                var compileShader = b.addSystemCommand(&[_][]const u8{ "glslangValidator", "-V", source, "-o", compiled }); //"-g", "-Od",
                installShader.step.dependOn(&compileShader.step);
            }
        }
    }

    exe.linkSystemLibrary("c");
    exe.addLibPath("V-EZ/Bin/x86_64/");
    exe.linkSystemLibrary("VEZ");

    if (target.getOsTag() == .windows) { // uses respective standard installation paths
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("shell32");

        exe.addLibPath("C:/Program Files (x86)/GLFW/lib-vc2019");
        exe.linkSystemLibrary("glfw3");
        var vkbase = std.fs.cwd().openDir("C:/VulkanSDK", .{ .access_sub_paths = false, .iterate = true }) catch unreachable;
        defer vkbase.close();
        // TODO: find newest version
        const first = vkbase.iterate().next() catch unreachable orelse unreachable;
        const vkpath = join(b, join(b, "C:/VulkanSDK", first.name), "Lib");
        exe.addLibPath(vkpath);
        exe.linkSystemLibrary("vulkan-1");

        const dll = b.addInstallBinFile("./V-EZ/Bin/x86_64/VEZ.dll", "VEZ.dll");
        exe.step.dependOn(&dll.step);
    } else {
        exe.linkSystemLibrary("glfw");
        exe.linkSystemLibrary("vulkan");
    }
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

// the Zig buildsystem needs to provide such generalized build caching
fn needs_update(a: []const u8, b: []const u8) bool {
    var a_time = get_mtime(a) orelse return true;
    var b_time = get_mtime(b) orelse return true;
    return a_time > b_time;
}

fn get_mtime(path: []const u8) ?i128 {
    const f = std.fs.cwd().openFile(path, .{ .read = false, .write = false}) catch |err|
    switch (err) {
        error.FileNotFound => return null,
        else => unreachable
    };
    defer f.close();

    const stats = f.stat() catch return null;
    return stats.mtime;
}