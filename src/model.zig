const std = @import("std");
const roundUp = @import("base.zig").roundUp;
const Allocator = std.mem.Allocator;

pub fn load(allocator: *Allocator, width: u32) !SerialModel {
    var tree = try create(allocator);
    defer allocator.free(tree);

    const height = roundUp(@intCast(u32, tree.len), width / 4) * 2;

    const pixelData = try allocator.alloc(u8, width * height);
    errdefer allocator.free(pixelData);
    var octree = try allocator.alloc([2]i32, tree.len);

    for (tree) |node, i| {
        octree[i] = .{ node.parent, node.child };

        const val = discretize(node.values, -1, 3);
        var basei = 2 * width * (4 * i / width) + 4 * i % width;
        pixelData[basei] = val[0];
        pixelData[basei + 1] = val[1];
        pixelData[basei + 2] = val[2];
        pixelData[basei + 3] = val[3];
        basei += width;
        pixelData[basei] = val[4];
        pixelData[basei + 1] = val[5];
        pixelData[basei + 2] = val[6];
        pixelData[basei + 3] = val[7];
    }

    return SerialModel{
        .tree = octree,
        .values = pixelData,
        .width = width,
        .height = height,
    };
}

fn discretize(x: [8]f32, from: f32, to: f32) [8]u8 {
    var res: [8]u8 = undefined;
    for (x) |val, i| {
        const v = (val - from) / to - from;
        res[i] = @floatToInt(u8, std.math.clamp(v, 0, 1) * 255);
    }
    return res;
}

const SerialModel = struct {
    tree: [][2]i32,
    values: []u8,
    width: u32,
    height: u32,

    pub fn deinit(self: @This(), allocator: *Allocator) void {
        allocator.free(self.tree);
        allocator.free(self.values);
    }
};

fn create(allocator: *Allocator) ![]OctNode {
    var tree = try allocator.alloc(OctNode, 1);
    tree[0] = .{
        .parent = -1,
        .child = -1,
        .values = .{
            1.3, 1, 1, 0.6, 1, 0.6, 0.6, -0.4,
        },
    };
    return tree;
}

pub const OctNode = struct {
    parent: i32,
    child: i32,
    values: [8]f32,
};
