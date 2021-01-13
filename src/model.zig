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

// TODO: handle restrictive maxImageDimension2D
const texwidth = 16384;
const valwidth = texwidth * 2;

pub const valpernode = 2;
pub const subdiv = 2;

const debug_construction = true;
pub var max_depth: u32 = 10;
const padding = 0.1;

pub const ChildRefs = [8]i32;

pub const SerialModel = struct {
    tree: []ChildRefs,
    values: []u8,
    width: u32,
    height: u32,

    pub fn deinit(self: @This(), allocator: *Allocator) void {
        allocator.free(self.tree);
        allocator.free(self.values);
    }
};

const Ref = union(enum) {
    full_node: usize,
    leaf_node: usize,
    no_child: void,
};

pub const OctNode = struct {
    children: [8]Ref = [1]Ref{.no_child} ** 8,
    values: [8]u8 = [_]u8{0} ** 8,
};

pub fn load(allocator: *Allocator, path: []const u8) !SerialModel {
    const stdout = std.io.getStdOut().outStream();
    var start = std.time.milliTimestamp();
    if (std.mem.endsWith(u8, path, ".adf")) {
        const adf = try load_adf.load(allocator, path);
        try stdout.print("Loaded {} in {} ms\n", .{ path, std.time.milliTimestamp() - start });
        return adf;
    }
    var m = gen: {
        var verts: []Vertex = undefined;
        if (std.mem.endsWith(u8, path, ".ply")) {
            verts = try load_ply.load(allocator, path);
            try stdout.print("Loaded {} in {} ms\n", .{ path, std.time.milliTimestamp() - start });
        } else {
            return error.FormatNotSupported;
        }
        defer allocator.free(verts);

        start = std.time.milliTimestamp();
        var mdl = try sdfGen(allocator, verts);
        try stdout.print("Genarated adf in {} ms\n", .{std.time.milliTimestamp() - start});
        break :gen mdl;
    };

    const saveto = try std.mem.join(allocator, ".", &[_][]const u8{ path[0..(path.len - 4)], "adf" });
    defer allocator.free(saveto);
    try load_adf.save(m, saveto);

    return m;
}

// fn serialize(tree: []const OctNode, current: usize, nodes: [][2]i32, values: []u8, val_width: usize) void {}

var model: ArrayList(OctNode) = undefined;
var leaves: ArrayList([8]u8) = undefined;

pub fn sdfGen(allocator: *Allocator, vertices: []Vertex) !SerialModel { // (Vertex *raw_vertices, int32_t vertexcount, int32_t depth)
    @setRuntimeSafety(debug_construction);
    normalize(vertices);
    model = ArrayList(OctNode).init(allocator);
    defer model.deinit();
    leaves = ArrayList([8]u8).init(allocator);
    defer leaves.deinit();
    {
        possibleBuffer = try allocator.alloc(Vertex, vertices.len * 12);
        defer allocator.free(possibleBuffer);

        _ = try construct(vertices, 0, vec.zero(), 2);
    }
    const values_count = model.items.len + leaves.items.len;
    const height = roundUp(@intCast(u32, values_count), texwidth / 2) * 2;

    const pixelData = try allocator.alloc(u8, texwidth * 2 * height);
    errdefer allocator.free(pixelData);
    var octree = try allocator.alloc(ChildRefs, model.items.len);

    for (model.items) |node, i| {
        for (octree[i]) |*treenode, j| {
            treenode.* = switch (node.children[j]) {
                .full_node => |index| @intCast(i32, index),
                .leaf_node => |index| @intCast(i32, model.items.len + index),
                .no_child => -1,
            };
        }

        const val = node.values;
        const texbase = 2 * valwidth * (4 * i / valwidth) + 4 * i % valwidth;

        var x: usize = 0;
        while (x < valpernode) : (x += 1) {
            var y: usize = 0;
            while (y < valpernode) : (y += 1) {
                var z: usize = 0;
                while (z < valpernode) : (z += 1) {
                    const vali = x + y * valpernode + z * valpernode * valpernode;
                    const texi = texbase + z + x * valpernode + y * valwidth;
                    pixelData[texi] = val[vali];
                }
            }
        }
    }

    for (leaves.items) |val, leafi| {
        const i = leafi + model.items.len;
        const texbase = 2 * valwidth * (4 * i / valwidth) + 4 * i % valwidth;

        var x: usize = 0;
        while (x < valpernode) : (x += 1) {
            var y: usize = 0;
            while (y < valpernode) : (y += 1) {
                var z: usize = 0;
                while (z < valpernode) : (z += 1) {
                    const vali = x + y * valpernode + z * valpernode * valpernode;
                    const texi = texbase + z + x * valpernode + y * valwidth;
                    pixelData[texi] = val[vali];
                }
            }
        }
    }

    return SerialModel{
        .tree = octree,
        .values = pixelData,
        .width = texwidth,
        .height = height,
    };
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
        vert.Position.z *= -1;
        vert.Normal.y *= -1;
        vert.Normal.z *= -1;
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

fn construct(vertices: []Vertex, depth: i32, pos: vec, center_value: f32) Allocator.Error!Ref {
    @setRuntimeSafety(debug_construction);
    const scale = math.pow(f32, 0.5, @intToFloat(f32, depth));
    const center = pos.add(vec.one().scale(0.5 * scale));

    const start = possibleCount;
    var possible = try getPossible(center, center_value + @sqrt(3.0) / 2.0 * scale, vertices);
    defer possibleCount = start;

    var values: [8]f32 = undefined;
    for (values) |*val, i| {
        val.* = distanceAt(pos.add(split(i).scale(scale)), possible);
    }
    var current = OctNode{ .values = discretize(values, scale) };
    var this: Ref = .no_child;

    if (depth < max_depth) {

        // var do_subdivide = [1]bool{false} ** 8;
        var i: usize = 0;
        const subscale = scale * 0.5;
        while (i < 8) : (i += 1) {
            // TODO: move fixed point to remove redundancy
            const subpos = pos.add(split(i).scale(subscale));
            const subcenter = subpos.add(vec.one().scale(0.5 * subscale));
            const subcenter_value = trueDistanceAt(subcenter, vertices);

            if (subcenter_value < subscale * @sqrt(3.0)) {
                if (this == .no_child) {
                    this = .{ .full_node = model.items.len };
                    try model.append(current);
                }
                const child_p = try construct(possible, depth + 1, subpos, subcenter_value);
                model.items[this.full_node].children[i] = child_p;
            }
        }
    }

    if (this == .no_child) {
        this = .{ .leaf_node = leaves.items.len };
        try leaves.append(current.values);
    }
    return this;
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
    @setRuntimeSafety(debug_construction);
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
    @setRuntimeSafety(debug_construction);
    var minDistance = math.inf(f32);

    for (vertices) |v| {
        const delta = v.Position.sub(p);
        if (delta.dot(delta) < minDistance) {
            minDistance = delta.dot(delta);
        }
    }

    if (math.isInf(minDistance) or math.isNan(minDistance))
        @panic("Invalid vertices");

    return @sqrt(minDistance);
}
fn distanceAt(p: vec, vertices: []Vertex) f32 {
    @setRuntimeSafety(debug_construction);
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
        @panic("Invalid vertices");

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
