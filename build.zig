const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = .Debug; //b.standardReleaseOptions();

    const exe = b.addExecutable("v-ez-test", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.setLibCFile("libc.txt");
    exe.addLibPath("../zforeign/V-EZ/Bin/x86_64/");
    exe.addPackagePath("zalgebra", "zalgebra/src/main.zig");

    exe.linkSystemLibrary("VEZ");
    exe.linkSystemLibrary("glfw");
    exe.linkSystemLibrary("vulkan");
    exe.linkSystemLibrary("c");
    exe.install();

    exe.step.dependOn(&b.addInstallFileWithDir("src/shaders/SimpleQuad.comp", .Bin, "shaders/SimpleQuad.comp").step);
    exe.step.dependOn(&b.addInstallFileWithDir("src/shaders/SimpleQuad.vert", .Bin, "shaders/SimpleQuad.vert").step);
    exe.step.dependOn(&b.addInstallFileWithDir("src/shaders/SimpleQuad.frag", .Bin, "shaders/SimpleQuad.frag").step);

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
