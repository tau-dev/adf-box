const std = @import("std");
const mem = std.mem;
const Writer = std.fs.File.Writer;
const Reader = std.fs.File.Reader;
const Allocator = mem.Allocator;

const Model = @import("model.zig");
const SerialModel = Model.SerialModel;
const ChildRefs = Model.ChildRefs;
const MaterialInfo = Model.MaterialInfo;

const magic = "asdf-box";
const version = "0.1.0";

pub fn load(allocator: *Allocator, filename: []const u8) !SerialModel {
    var file = try std.fs.cwd().openFile(filename, .{ .read = true, .write = false, .lock = .None });
    defer file.close();
    var reader = file.reader();

    if (!expect(&reader, magic)) return error.FormatInvalid;
    if (!expect(&reader, version)) return error.FormatNotSupported;

    const treelength = @intCast(usize, try reader.readIntLittle(i32));
    var model = SerialModel{
        .tree = undefined,
        .values = undefined,
        .material = undefined,
        .width = @intCast(u32, try reader.readIntLittle(i32)),
        .height = @intCast(u32, try reader.readIntLittle(i32)),
    };

    model.tree = try allocator.alloc(ChildRefs, treelength);
    errdefer allocator.free(model.tree);
    model.material = try allocator.alloc(MaterialInfo, treelength);
    errdefer allocator.free(model.material);

    try reader.readNoEof(mem.sliceAsBytes(model.tree));
    try reader.readNoEof(mem.sliceAsBytes(model.material));

    for (model.tree) |*node| {
        for (node.*) |*v| {
            v.* = mem.littleToNative(i32, v.*);
        }
    }
    for (model.material) |*mat| {
        mat.* = mem.littleToNative(u32, mat.*);
    }

    model.values = try allocator.alloc(u8, model.width * model.height * @import("model.zig").valres);
    errdefer allocator.free(model.values);
    try reader.readNoEof(model.values);

    return model;
}

fn expect(read: *Reader, expected: []const u8) bool {
    return read.isBytes(expected) catch |err| false;
}

pub fn save(model: SerialModel, filename: []const u8) !void {
    var file = try std.fs.cwd().createFile(filename, .{ .read = false, .exclusive = false, .lock = .Exclusive });
    defer file.close();
    var writer = file.writer();
    try writer.writeAll(magic ++ version);

    try write(&writer, @intCast(i32, model.tree.len));
    try write(&writer, @intCast(i32, model.width));
    try write(&writer, @intCast(i32, model.height));

    for (model.tree) |*node| {
        for (node.*) |*v| {
            v.* = mem.nativeToLittle(i32, v.*);
        }
    }
    for (model.material) |*mat| {
        mat.* = mem.nativeToLittle(u32, mat.*);
    }
    defer {
        for (model.tree) |*node| {
            for (node.*) |*v| {
                v.* = mem.littleToNative(i32, v.*);
            }
        }
        for (model.material) |*mat| {
            mat.* = mem.littleToNative(u32, mat.*);
        }
    }

    try writer.writeAll(mem.sliceAsBytes(model.tree));
    try writer.writeAll(mem.sliceAsBytes(model.material));
    try writer.writeAll(model.values);
}

fn write(w: *Writer, i: i32) !void {
    try w.writeIntLittle(i32, i);
}
