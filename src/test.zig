const std = @import("std");

pub inline fn VK_MAKE_VERSION(major: var, minor: var, patch: var) @TypeOf(((if (@typeInfo(@TypeOf(major)) == .Pointer) @ptrCast(uint32_t, @alignCast(@alignOf(uint32_t.Child), major)) else if (@typeInfo(@TypeOf(major)) == .Int and @typeInfo(uint32_t) == .Pointer) @intToPtr(uint32_t, major) else @as(uint32_t, major)) << 22) | (((if (@typeInfo(@TypeOf(minor)) == .Pointer) @ptrCast(uint32_t, @alignCast(@alignOf(uint32_t.Child), minor)) else if (@typeInfo(@TypeOf(minor)) == .Int and @typeInfo(uint32_t) == .Pointer) @intToPtr(uint32_t, minor) else @as(uint32_t, minor)) << 12) | (if (@typeInfo(@TypeOf(patch)) == .Pointer) @ptrCast(uint32_t, @alignCast(@alignOf(uint32_t.Child), patch)) else if (@typeInfo(@TypeOf(patch)) == .Int and @typeInfo(uint32_t) == .Pointer) @intToPtr(uint32_t, patch) else @as(uint32_t, patch)))) {
    return ((if (@typeInfo(@TypeOf(major)) == .Pointer) @ptrCast(uint32_t, @alignCast(@alignOf(uint32_t.Child), major)) else if (@typeInfo(@TypeOf(major)) == .Int and @typeInfo(uint32_t) == .Pointer) @intToPtr(uint32_t, major) else @as(uint32_t, major)) << 22) | (((if (@typeInfo(@TypeOf(minor)) == .Pointer) @ptrCast(uint32_t, @alignCast(@alignOf(uint32_t.Child), minor)) else if (@typeInfo(@TypeOf(minor)) == .Int and @typeInfo(uint32_t) == .Pointer) @intToPtr(uint32_t, minor) else @as(uint32_t, minor)) << 12) | (if (@typeInfo(@TypeOf(patch)) == .Pointer) @ptrCast(uint32_t, @alignCast(@alignOf(uint32_t.Child), patch)) else if (@typeInfo(@TypeOf(patch)) == .Int and @typeInfo(uint32_t) == .Pointer) @intToPtr(uint32_t, patch) else @as(uint32_t, patch)));
}

pub fn main() !void {
    //std.debug.warn("{}", .{VK_MAKE_VERSION(1, 0, 0)});
}
