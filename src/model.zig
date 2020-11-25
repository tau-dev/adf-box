const std = @import("std");
const math = std.math;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const mat = @import("zalgebra");
const mat4 = mat.mat4;
const vec = mat.vec3;

const roundUp = @import("base.zig").roundUp;

const load_ply = @import("load_ply.zig");
const load_adf = @import("load_adf.zig");
const Vertex = load_ply.Vertex;

const texwidth = 2048;

pub const valpernode = 2;
pub const subdiv = 2;

const max_depth = 6;
const padding = 0.2;

pub const SerialModel = struct {
    tree: [][2]i32,
    values: []u8,
    width: u32,
    height: u32,

    pub fn deinit(self: @This(), allocator: *Allocator) void {
        allocator.free(self.tree);
        allocator.free(self.values);
    }
};

pub const OctNode = struct {
    parent: i32 = -1,
    children: i32 = -1,
    values: [8]u8 = [_]u8{0} ** 8,
};

var model: ArrayList(OctNode) = undefined;

pub fn load(allocator: *Allocator, path: []const u8) !SerialModel {
    if (std.mem.endsWith(u8, path, ".adf")) {
        return try load_adf.load(allocator, path);
    }

    var verts: []Vertex = undefined;
    if (std.mem.endsWith(u8, path, ".ply")) {
        verts = try load_ply.load(allocator, path);
        errdefer allocator.free(verts);
    } else {
        return error.FormatNotSupported;
    }
    defer allocator.free(verts);

    var tree = try sdfGen(allocator, verts);
    defer allocator.free(tree);

    const height = roundUp(@intCast(u32, tree.len), texwidth / 4) * 2;

    const pixelData = try allocator.alloc(u8, texwidth * height);
    errdefer allocator.free(pixelData);
    var octree = try allocator.alloc([2]i32, tree.len);

    for (tree) |node, i| {
        octree[i] = .{ node.parent, node.children };

        const val = node.values;
        const texbase = 2 * texwidth * (4 * i / texwidth) + 4 * i % texwidth;

        var x: usize = 0;
        while (x < valpernode) : (x += 1) {
            var y: usize = 0;
            while (y < valpernode) : (y += 1) {
                var z: usize = 0;
                while (z < valpernode) : (z += 1) {
                    const vali = x + y * valpernode + z * valpernode * valpernode;
                    const texi = texbase + x + z * valpernode + y * texwidth;
                    pixelData[texi] = val[vali];
                }
            }
        }
    }

    const m = SerialModel{
        .tree = octree,
        .values = pixelData,
        .width = texwidth,
        .height = height,
    };

    const saveto = try std.mem.join(allocator, ".", &[_][]const u8{ path[0..(path.len - 4)], "adf" });
    defer allocator.free(saveto);
    try load_adf.save(m, saveto);

    return m;
}

// fn serialize(tree: []const OctNode, current: usize, nodes: [][2]i32, values: []u8, val_width: usize) void {}

pub fn sdfGen(allocator: *Allocator, vertices: []Vertex) ![]OctNode { // (Vertex *raw_vertices, int32_t vertexcount, int32_t depth)
    normalize(vertices);
    model = try ArrayList(OctNode).initCapacity(allocator, try math.powi(usize, 4, max_depth));
    defer model.deinit();

    try model.append(OctNode{});
    possibleBuffer = try allocator.alloc(Vertex, vertices.len * 12);
    defer allocator.free(possibleBuffer);

    try construct(vertices, 0, vec.zero(), 0);

    return model.toOwnedSlice();
}

fn split(i: usize) vec {
    return vec.new(
        @intToFloat(f32, i % 2),
        @intToFloat(f32, (i / 2) % 2),
        @intToFloat(f32, (i / 2 / 2) % 2),
    );
}
fn normalize(vertices: []Vertex) void {
    for (vertices) |*vert| {
        vert.Position.y *= -1;
        vert.Normal.y *= -1;
    }
    var lower = vec.one().scale(math.inf(f32));
    var higher = vec.one().scale(-math.inf(f32));
    for (vertices) |vert| {
        lower = vec.min(lower, vert.Position);
        higher = vec.max(higher, vert.Position);
    }

    const extent = higher.sub(lower);
    const size = math.max(extent.x, math.max(extent.y, extent.z));

    const padded_size = size * (1 + padding);
    const padded_base = lower.sub(vec.one().scale(0.5 * padding * size)); //.add(vec.one().scale(0.003));

    for (vertices) |*vert| {
        vert.Position = vert.Position.sub(padded_base).scale(1 / padded_size);
    }
}

const half_sqrt3 = @sqrt(3.0) / 2.0;
fn construct(vertices: []Vertex, depth: i32, pos: vec, insert: usize) Allocator.Error!void {
    @setRuntimeSafety(false);
    const current = &model.items[insert];
    const scale = math.pow(f32, 0.5, @intToFloat(f32, depth));
    var center = pos.add(vec.one().scale(0.5 * scale));

    var center_value = trueDistanceAt(center, vertices);
    const start = possibleCount;
    var possible = try getPossible(center, center_value + half_sqrt3 * scale, vertices);
    // defer possibleCount = start;

    var values: [8]f32 = undefined;
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        values[i] = distanceAt(pos.add(split(i).scale(scale)), possible);
    }
    current.values = discretize(values, scale);

    if (depth >= max_depth) { // or center_value > scale * 2) { // don't split
        return;
    }

    const childrenIndex = model.items.len;
    current.children = @intCast(i32, childrenIndex);

    i = 0;
    while (i < 8) : (i += 1) {
        try model.append(.{ .parent = @intCast(i32, insert) });
    }

    i = 0;
    while (i < 8) : (i += 1) {
        try construct(possible, depth + 1, pos.add(split(i).scale(scale / 2)), childrenIndex + i);
    }
    possibleCount = start;
}

const from: f32 = -1;
const to: f32 = 3;
fn discretize(x: [8]f32, scale: f32) [8]u8 {
    var res: [8]u8 = undefined;
    for (x) |val, i| {
        const v = (val / scale - from) / (to - from);
        res[i] = @floatToInt(u8, std.math.clamp(v, 0, 1) * 255);
    }
    return res;
}

var possibleBuffer: []Vertex = undefined;
var possibleCount: usize = 0;

fn getPossible(p: vec, minDistance: f32, possible: []Vertex) ![]Vertex {
    const start = possibleCount;
    var minSquared = minDistance; // * global_scale;
    minSquared *= minSquared;

    for (possible) |vert| {
        const delta = vert.Position.sub(p);
        if (delta.dot(delta) < minSquared) {
            possibleBuffer[possibleCount] = vert;
            possibleCount += 1;
        }
    }
    return possibleBuffer[start..possibleCount];
}

fn trueDistanceAt(p: vec, vertices: []Vertex) f32 {
    var minDistance = math.inf(f32);

    for (vertices) |v| {
        const delta = v.Position.sub(p);
        if (delta.dot(delta) < minDistance) {
            minDistance = delta.dot(delta);
        }
    }

    if (math.isInf(minDistance) or math.isNan(minDistance))
        unreachable;

    return @sqrt(minDistance);
}
fn distanceAt(p: vec, vertices: []Vertex) f32 {
    var closest: Vertex = undefined;
    var minDistance = math.inf(f32);

    for (vertices) |v| {
        const delta = v.Position.sub(p);
        if (delta.dot(delta) < minDistance) {
            minDistance = delta.dot(delta);
            closest = v;
        }
    }

    if (math.isInf(minDistance) or math.isNan(minDistance))
        unreachable;

    minDistance = @sqrt(minDistance);
    if (minDistance < 0.02) {
        minDistance = closest.Normal.scale(1 / closest.Normal.length()).dot(p.sub(closest.Position));
    } else if (inside(p, closest)) {
        minDistance *= -1;
    }

    return minDistance;
}
fn inside(p: vec, closest: Vertex) bool {
    return closest.Normal.dot(closest.Position.sub(p)) > 0;
}
