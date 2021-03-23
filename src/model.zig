const std = @import("std");
const math = std.math;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Thread = std.Thread;

const mat = @import("zalgebra");
const mat4 = mat.mat4;
const vec = mat.vec3;
var c_allocator = std.heap.c_allocator;

const roundUp = @import("base.zig").roundUp;

const load_ply = @import("load_ply.zig");
const load_adf = @import("load_adf.zig");
const Vertex = load_ply.Vertex;

// TODO: handle restrictive maxImageDimension2D
const texwidth = 16384;
const valwidth = texwidth * valres;

pub const valres = 4;
pub const valcount = valres * valres * valres;
pub const subdiv = 2;
pub const childcount = subdiv * subdiv * subdiv;

const fork_depth = 2;
pub var max_depth: u32 = 5;
const padding = 0.1;

pub const ChildRefs = [childcount]i32;

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
    parallel_result: usize,
    none: void,
};

pub const OctNode = struct {
    children: [childcount]Ref = [_]Ref{.none} ** childcount,
    values: [valcount]u8 = [_]u8{0} ** valcount,
};

const Task = struct {
    const Self = @This();

    handle: *Thread,
    node_mem: *ArrayList(OctNode),
    leaf_mem: *ArrayList([valcount]u8),
    vertex_mem: []Vertex,
    // used for linearizing
    node_offset: usize = 0,
    leaf_offset: usize = 0,

    const Params = struct {
        vertices: []Vertex,
        depth: i32,
        pos: vec,
        center_value: f32,
        node_mem_ref: *ArrayList(OctNode),
        leaf_mem_ref: *ArrayList([valcount]u8),
        vertex_mem_ref: []Vertex,
    };

    fn launch(vertices: []Vertex, depth: i32, pos: vec, center_value: f32) !Self {
        var allocator = c_allocator;
        var self = Self{
            .handle = undefined,
            .node_mem = try allocator.create(ArrayList(OctNode)),
            .leaf_mem = try allocator.create(ArrayList([valcount]u8)),
            .vertex_mem = try allocator.alloc(Vertex, vertices.len * (max_depth - fork_depth + 1))
        };
        self.node_mem.* = ArrayList(OctNode).init(allocator);
        self.leaf_mem.* = ArrayList([valcount]u8).init(allocator);
        std.mem.copy(Vertex, self.vertex_mem, vertices);

        self.handle = try Thread.spawn(Params{
                .vertices = self.vertex_mem[0..vertices.len],
                .depth = depth,
                .pos = pos,
                .center_value = center_value,
                .node_mem_ref = self.node_mem,
                .leaf_mem_ref = self.leaf_mem,
                .vertex_mem_ref = self.vertex_mem,
            }, launched);
        return self;
    }
    fn launched(context: Params) void {
        forked = true;
        midnodes = context.node_mem_ref;
        leaves = context.leaf_mem_ref;

        possibleCount = context.vertices.len;
        possibleBuffer = context.vertex_mem_ref;
        defer c_allocator.free(possibleBuffer);

        _ = construct(context.vertices, context.depth, context.pos, context.center_value)
            catch @panic("TODO: Pass error back to parent thread");
    }
    fn wait(self: *Self) void {
        self.handle.wait();
    }
    fn deinit(self: *Self) void {
        var allocator = c_allocator;
        self.node_mem.deinit();
        c_allocator.destroy(self.node_mem);

        self.leaf_mem.deinit();
        c_allocator.destroy(self.leaf_mem);
    }
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
        if (!std.mem.endsWith(u8, path, ".ply")) {
            return error.FormatNotSupported;
        }
        verts = try load_ply.load(allocator, path);
        defer allocator.free(verts);
        try stdout.print("Loaded {} in {} ms\n", .{ path, std.time.milliTimestamp() - start });

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

threadlocal var midnodes: *ArrayList(OctNode) = undefined;
threadlocal var leaves: *ArrayList([valcount]u8) = undefined;
var parallel_tasks: ArrayList(Task) = undefined;

pub fn sdfGen(allocator: *Allocator, vertices: []Vertex) !SerialModel { // (Vertex *raw_vertices, int32_t vertexcount, int32_t depth)
    normalize(vertices);
    var node_mem = ArrayList(OctNode).init(allocator);
    defer node_mem.deinit();
    midnodes = &node_mem;
    var leaf_mem = ArrayList([valcount]u8).init(allocator);
    defer leaf_mem.deinit();
    leaves = &leaf_mem;

    parallel_tasks = ArrayList(Task).init(allocator);
    defer {
        for (parallel_tasks.items) |*p| {
            p.deinit();
        }
        parallel_tasks.deinit();
    }

    {
        possibleBuffer = try allocator.alloc(Vertex, vertices.len * (fork_depth + 1));
        defer allocator.free(possibleBuffer);

        _ = try construct(vertices, 0, vec.zero(), 2);
    }
    const tasks = parallel_tasks.items;

    var node_offset = midnodes.items.len;
    for (tasks) |*p| {
        p.wait();
        p.node_offset = node_offset;
        node_offset += p.node_mem.items.len;
    }
    var leaf_offset = node_offset + leaves.items.len;
    for (tasks) |*p| {
        p.leaf_offset = leaf_offset;
        leaf_offset += p.leaf_mem.items.len;
    }

    var octree = try allocator.alloc(ChildRefs, node_offset);

    const height = roundUp(@intCast(u32, leaf_offset), texwidth / valres) * valres;
    const pixelData = try allocator.alloc(u8, valwidth * height);
    errdefer allocator.free(pixelData);

    linearize(midnodes.items, leaves.items, 0, node_offset,
        octree, pixelData);

    for (tasks) |p| {
        linearize(p.node_mem.items, p.leaf_mem.items,
            p.node_offset, p.leaf_offset,
            octree, pixelData);
    }

    try std.io.getStdOut().writer().print(
        "mid nodes  {}\nleaf nodes {}\n", 
        .{ node_offset, leaf_offset - node_offset});

    return SerialModel{
        .tree = octree,
        .values = pixelData,
        .width = texwidth,
        .height = height,
    };
}

/// modifies vertices so that their coordinates are within a range of [-1,1].
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

fn linearize(
    nodes: []OctNode,
    leav: [][valcount]u8,
    node_start: usize,
    leaf_start: usize,
    octree: []ChildRefs,
    pixelData: []u8
) void {
    const tasks = parallel_tasks.items;
    for (nodes) |node, k| {
        const i = k + node_start;
        for (octree[i]) |*treenode, j| {
            treenode.* = switch (node.children[j]) {
                .full_node => |index| @intCast(i32, node_start + index),
                .leaf_node => |index| @intCast(i32, leaf_start + index),
                .parallel_result => |task| @intCast(i32, tasks[task].node_offset),
                .none => -1,
            };
        }
        const val = node.values;
        mapValToTexture(pixelData, node.values, i);
    }

    for (leav) |val, leafi| {
        const i = leafi + leaf_start;
        mapValToTexture(pixelData, val, i);
    }
}

fn mapValToTexture(tex: []u8, v: [valcount]u8, i: usize) void {
    // black magic index juggling
    const texbase = valres * valwidth * (valres * valres * i / valwidth)
                    + valres * valres * i % valwidth;
    
    var x: usize = 0;
    while (x < valres) : (x += 1) {
        var y: usize = 0;
        while (y < valres) : (y += 1) {
            var z: usize = 0;
            while (z < valres) : (z += 1) {
                const vali = x + y * valres + z * valres * valres;
                const texi = texbase + z + x * valres + y * valwidth;
                tex[texi] = v[vali];
            }
        }
    }
}

const ConstructError = Allocator.Error || Thread.SpawnError;
threadlocal var forked = false; // this is disgusting

fn construct(vertices: []Vertex, depth: i32, pos: vec, center_value: f32) ConstructError!Ref {
    if (depth == fork_depth and !forked) {
        try parallel_tasks.append(try Task.launch(vertices, depth, pos, center_value));
        return Ref{ .parallel_result = parallel_tasks.items.len - 1 };
    }
    const scale = math.pow(f32, 0.5, @intToFloat(f32, depth));
    const center = pos.add(vec.one().scale(0.5 * scale));

    const start = possibleCount;
    var possible = getPossible(center, center_value + @sqrt(3.0) / 2.0 * scale, vertices);
    defer possibleCount = start; // Not nice, but efficient.

    var values = discreteDistances(pos, scale, possible);

    if (depth >= max_depth) {
        try leaves.append(values);
        return Ref{ .leaf_node = leaves.items.len - 1 };
    }
    var this = try genChildren(pos, scale / subdiv, possible, depth);
    switch (this) {
        .leaf_node =>
            try leaves.append(values),
        .full_node => |f|
            midnodes.items[f].values = values,
        else => {}
    }
    return this;
}

fn genChildren(pos: vec, subscale: f32, possible: []Vertex, depth: i32) ConstructError!Ref {
    var has_children = false;
    var this: usize = 0;
    var i: usize = 0;
    while (i < childcount) : (i += 1) {
        const subpos = pos.add(splitChildIndex(i).scale(subscale));
        const subcenter = subpos.add(vec.one().scale(0.5 * subscale));
        const subcenter_value = trueDistanceAt(subcenter, possible);

        if (subcenter_value < subscale * @sqrt(3.0) or depth <= fork_depth + 1) {

            if (!has_children) {
                has_children = true;
                this = midnodes.items.len;
                try midnodes.append(OctNode{});
            }
            const child_p = try construct(possible, depth + 1, subpos, subcenter_value);
            
            midnodes.items[this].children[i] = child_p;
        }
    }
    if (!has_children) {
        return Ref{ .leaf_node = leaves.items.len };
    } else {
        return Ref{ .full_node = this };
    }
}


fn splitValueIndex(i: usize) vec {
    return vec.new(
        @intToFloat(f32, i % valres) / (valres - 1),
        @intToFloat(f32, (i / valres) % valres) / (valres - 1),
        @intToFloat(f32, (i / valres / valres) % valres) / (valres - 1),
    );
}
fn splitChildIndex(i: usize) vec {
    return vec.new(
        @intToFloat(f32, i % subdiv) / (subdiv - 1),
        @intToFloat(f32, (i / subdiv) % subdiv) / (subdiv - 1),
        @intToFloat(f32, (i / subdiv / subdiv) % subdiv) / (subdiv - 1),
    );
}

threadlocal var possibleBuffer: []Vertex = undefined;
threadlocal var possibleCount: usize = 0;

fn getPossible(p: vec, minDistance: f32, possible: []Vertex) []Vertex {
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
        @panic("Invalid vertices");

    return @sqrt(minDistance);
}


const from: f32 = -1;
const to: f32 = 3;

fn discreteDistances(pos: vec, scale: f32, possible: []Vertex) [valcount]u8 {
    var res: [valcount]u8 = undefined;
    for (res) |*r, i| {
        const value = distanceAt(pos.add(splitValueIndex(i).scale(scale)), possible);

        const v = (value / scale - from) / (to - from);
        r.* = @floatToInt(u8, std.math.clamp(v, 0, 1) * 255);
    }
    return res;
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
