const std = @import("std");
const Allocator = std.mem.Allocator;
const Reader = std.fs.File.Reader;
const ArrayList = std.ArrayList;

const builtin = @import("builtin");

const mat = @import("zalgebra");
const mat4 = mat.mat4;
const vec = mat.vec3;

const ParseError = error{
    FormatInvalid,
    FormatNotSupported,
} || Reader.Error || Allocator.Error;

fn errors(comptime f: anytype) type {
    return @typeInfo(@typeInfo(@TypeOf(f)).Fn.return_type.?).ErrorUnion.error_set;
}

pub const Vertex = struct {
    Position: vec,
    Normal: vec,
};

var format: Format = undefined;

const Format = enum {
    Ascii,
    BinaryLittleEndian,
    BinaryBigEndian,
};

const Element = struct {
    name: []const u8,
    count: usize,
    properties: ArrayList(Property),

    fn parseDefinition(allocator: *Allocator, reader: *Reader) !@This() {
        var name = try readWord(allocator, reader);
        errdefer allocator.free(name);

        var count_str = try readWord(allocator, reader);
        defer allocator.free(count_str);

        var count = std.fmt.parseUnsigned(usize, count_str, 10) catch |err| return error.FormatInvalid;
        var properties = ArrayList(Property).init(allocator);

        return @This(){
            .name = name,
            .count = count,
            .properties = properties,
        };
    }

    fn deinit(allocator: *Allocator) void {
        allocator.free(name);
        properties.deinit();
    }

    const Value = struct {
        properties: []Property.Value,

        fn deinit(self: @This(), allocator: *Allocator) void {
            for (self.properties) |prop| {
                prop.deinit(allocator);
            }

            allocator.free(self.properties);
        }
    };

    fn read(self: @This(), allocator: *Allocator, reader: *Reader) !Value {
        var res = try allocator.alloc(Property.Value, self.properties.items.len);
        errdefer allocator.free(res);

        for (self.properties.items) |p, i| {
            res[i] = try p.read(allocator, reader);
        }

        return @This().Value{ .properties = res };
    }
    fn ignore(self: @This(), reader: *Reader) !void {
        for (self.properties.items) |p, i| {
            try p.ignore(reader);
        }
    }
};

const Property = union(enum) {
    const Self = @This();

    const Type = enum {
        Char,
        Uchar,
        Short,
        Ushort,
        Int,
        Uint,
        Float,
        Double,

        fn parse(name: []const u8) ?@This() {
            if (eql(name, "char")) {
                return .Char;
            } else if (eql(name, "uchar")) {
                return .Uchar;
            } else if (eql(name, "short")) {
                return .Short;
            } else if (eql(name, "ushort")) {
                return .Ushort;
            } else if (eql(name, "int")) {
                return .Int;
            } else if (eql(name, "uint")) {
                return .Uint;
            } else if (eql(name, "float")) {
                return .Float;
            } else if (eql(name, "double")) {
                return .Double;
            } else {
                return null;
            }
        }

        fn read(self: @This(), reader: *Reader) !Value {
            return switch (self) {
                .Char => .{ .Char = try readVal(reader, i8) },
                .Uchar => .{ .Uchar = try readVal(reader, u8) },
                .Short => .{ .Short = try readVal(reader, i16) },
                .Ushort => .{ .Ushort = try readVal(reader, u16) },
                .Int => .{ .Int = try readVal(reader, i32) },
                .Uint => .{ .Uint = try readVal(reader, u32) },
                .Float => .{ .Float = try readVal(reader, f32) },
                .Double => .{ .Double = try readVal(reader, f64) },
            };
        }
        fn size(self: @This()) usize {
            return switch (self) {
                .Char, .Uchar => 1,
                .Short, .Ushort => 2,
                .Int, .Uint, .Float => 4,
                .Double => 8,
            };
        }
    };
    const List = struct {
        const CountType = enum {
            Uchar,
            Ushort,
            Uint,
        };

        count: CountType,
        content: Type,

        fn parseDefinition(allocator: *Allocator, reader: *Reader) !@This() {
            var self: @This() = undefined;

            var count = try readWord(allocator, reader);
            defer allocator.free(count);
            if (eql(count, "uchar")) {
                self.count = .Uchar;
            } else if (eql(count, "ushort")) {
                self.count = .Ushort;
            } else if (eql(count, "uint")) {
                self.count = .Uint;
            } else {
                return error.FormatInvalid;
            }
            var content = try readWord(allocator, reader);
            defer allocator.free(content);
            self.content = Type.parse(content) orelse return error.FormatInvalid;

            var name = try readWord(allocator, reader);
            defer allocator.free(name);

            return self;
        }
        fn read(self: @This(), allocator: *Allocator, reader: *Reader) !Value {
            var count: usize = switch (self.count) {
                .Uchar => @intCast(usize, try readVal(reader, u8)),
                .Ushort => @intCast(usize, try readVal(reader, u16)),
                .Uint => @intCast(usize, try readVal(reader, u32)),
            };
            var val: Value = undefined;
            switch (self.content) {
                .Char => val.CharList = try readList(allocator, reader, i8, count),
                .Uchar => val.UcharList = try readList(allocator, reader, u8, count),
                .Short => val.ShortList = try readList(allocator, reader, i16, count),
                .Ushort => val.UshortList = try readList(allocator, reader, u16, count),
                .Int => val.IntList = try readList(allocator, reader, i32, count),
                .Uint => val.UintList = try readList(allocator, reader, u32, count),
                .Float => val.FloatList = try readList(allocator, reader, f32, count),
                .Double => val.DoubleList = try readList(allocator, reader, f64, count),
            }
            return val;
        }
        fn readList(allocator: *Allocator, reader: *Reader, comptime T: type, size: usize) ![]T {
            var content = try allocator.alloc(T, size);
            errdefer allocator.free(content);

            for (content) |*item| {
                item.* = try readVal(reader, T);
            }
            return content;
        }
    };

    basic: Type,
    list: List,

    fn parseDefinition(allocator: *Allocator, reader: *Reader) !Self {
        var kind = try readWord(allocator, reader);

        var self: Self = undefined;

        if (Type.parse(kind)) |t| {
            var name = try readWord(allocator, reader);
            defer allocator.free(name);

            return Self{ .basic = t };
        } else if (eql(kind, "list")) {
            return Self{ .list = try List.parseDefinition(allocator, reader) };
        } else {
            return error.FormatInvalid;
        }
    }

    fn read(self: @This(), allocator: *Allocator, reader: *Reader) (errors(Type.read) || errors(List.read))!Value { //@typeInfo(@typeInfo(@TypeOf(Type.read)).Fn.return_type.?).ErrorUnion.error_set
        return switch (self) {
            .basic => |t| t.read(reader),
            .list => |l| l.read(allocator, reader),
        };
    }
    fn ignore(self: @This(), reader: *Reader) !void {
        switch (self) {
            .list => |l| {
                const count: usize = switch (l.count) {
                    .Uchar => @intCast(usize, try readVal(reader, u8)),
                    .Ushort => @intCast(usize, try readVal(reader, u16)),
                    .Uint => @intCast(usize, try readVal(reader, u32)),
                };
                try reader.skipBytes(l.content.size() * count, Reader.SkipBytesOptions{});
            },
            .basic => |b| try reader.skipBytes(b.size(), Reader.SkipBytesOptions{}),
        }
    }

    const Value = union(enum) {
        Char: i8,
        Uchar: u8,
        Short: i16,
        Ushort: u16,
        Int: i32,
        Uint: u32,
        Float: f32,
        Double: f64,
        CharList: []i8,
        UcharList: []u8,
        ShortList: []i16,
        UshortList: []u16,
        IntList: []i32,
        UintList: []u32,
        FloatList: []f32,
        DoubleList: []f64,

        fn deinit(self: @This(), allocator: *Allocator) void {
            switch (self) {
                .CharList => |val| allocator.free(val),
                .UcharList => |val| allocator.free(val),
                .ShortList => |val| allocator.free(val),
                .UshortList => |val| allocator.free(val),
                .IntList => |val| allocator.free(val),
                .UintList => |val| allocator.free(val),
                .FloatList => |val| allocator.free(val),
                .DoubleList => |val| allocator.free(val),
                else => {},
            }
        }
    };
};

fn readVal(read: *Reader, comptime T: type) ParseError!T {
    return switch (format) {
        .Ascii => readAscii(read, T),
        .BinaryBigEndian, .BinaryLittleEndian => switch (T) {
            u8, i8, u16, i16, u32, i32 => read.readInt(T, if (format == .BinaryLittleEndian) builtin.Endian.Little else builtin.Endian.Big) catch |err| switch (err) {
                error.EndOfStream => error.FormatInvalid,
                else => |e| e,
            },
            f32 => @bitCast(f32, try readVal(read, u32)),
            f64 => @bitCast(f64, try readVal(read, u64)),
            else => @compileError("type not supported"),
        },
    };
}

fn readAscii(read: *Reader, comptime T: type) !T {
    var buf = [1]u8{0} ** 32;

    var count: usize = 0;

    while (true) {
        if (count >= buf.len) {
            return error.FormatInvalid;
        }
        const r = read.readByte() catch |err| switch (err) {
            error.EndOfStream => if (count > 0) {
                break;
            } else {
                return error.FormatInvalid;
            },
            else => |e| return e,
        };
        if (std.ascii.isSpace(r)) {
            if (count > 0)
                break;
        } else {
            buf[count] = r;
            count += 1;
        }
    }

    return switch (T) {
        u8, i8, u16, i16, u32, i32 => std.fmt.parseInt(T, buf[0..count], 10) catch |err| return error.FormatInvalid,
        f32, f64 => std.fmt.parseFloat(T, buf[0..count]) catch |err| {
            return error.FormatInvalid;
        },
        else => @compileError("type not supported"),
    };
}

fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

/// caller owns returned memory
pub fn load(allocator: *Allocator, path: []const u8) ![]Vertex {
    var file = try std.fs.cwd().openFile(path, .{ .read = true, .write = false, .lock = .None });
    defer file.close();
    var reader = file.reader();

    if (!expect(&reader, "ply\nformat ")) {
        return error.FormatInvalid;
    }

    var formatString = try readWord(allocator, &reader);
    defer allocator.free(formatString);
    format = if (eql(formatString, "ascii"))
        Format.Ascii
    else if (eql(formatString, "binary_little_endian"))
        Format.BinaryLittleEndian
    else if (eql(formatString, "binary_big_endian"))
        Format.BinaryBigEndian
    else
        return error.FormatNotSupported;

    if (!expect(&reader, "1.0\n")) {
        return error.FormatNotSupported;
    }

    var elements = try readHeader(allocator, &reader);
    defer allocator.free(elements);

    for (elements) |elem| {
        if (eql(elem.name, "vertex")) {
            if (elem.properties.items.len != 6) {
                return error.FormatNotSupported;
            }
            for (elem.properties.items) |p| {
                // TODO: property names
                switch (p) {
                    .basic => |b| if (b != Property.Type.Float) return error.FormatNotSupported,
                    else => return error.FormatNotSupported,
                }
            }

            const vertices = try allocator.alloc(Vertex, elem.count);
            errdefer allocator.free(vertices);

            var i: usize = 0;
            while (i < elem.count) : (i += 1) {
                // const e = try elem.read(allocator, &reader);
                // defer e.deinit(allocator);
                vertices[i] = Vertex{
                    .Position = .{
                        .x = try readVal(&reader, f32),
                        .y = try readVal(&reader, f32),
                        .z = try readVal(&reader, f32),
                    },
                    .Normal = .{
                        .x = try readVal(&reader, f32),
                        .y = try readVal(&reader, f32),
                        .z = try readVal(&reader, f32),
                    },
                };
            }
            return vertices;
        } else {
            var i: usize = 0;
            while (i < elem.count) : (i += 1) {
                try elem.ignore(&reader);
            }
        }
    }
    return error.FormatNotSupported;
}

fn expect(read: *Reader, expected: []const u8) bool {
    return read.isBytes(expected) catch |err| false;
}

/// caller owns returned memory
fn readWord(allocator: *Allocator, read: *Reader) ![]u8 {
    var l = std.ArrayList(u8).init(allocator);
    defer l.deinit();

    while (true) {
        const r = read.readByte() catch |err| switch (err) {
            error.EndOfStream => if (l.items.len > 0) {
                break;
            } else {
                return error.FormatInvalid;
            },
            else => return err,
        };
        if (std.ascii.isSpace(r)) {
            if (l.items.len > 0)
                break;
        } else {
            try l.append(r);
        }
    }

    return l.toOwnedSlice();
}

/// caller owns returned memory
fn readHeader(allocator: *Allocator, read: *Reader) ![]Element {
    var elems = std.ArrayList(Element).init(allocator);
    defer elems.deinit();

    while (true) {
        var word = readWord(allocator, read) catch |err| switch (err) {
            error.EndOfStream => return error.FormatInvalid,
            else => |e| return e,
        };

        defer allocator.free(word);

        if (eql(word, "end_header")) {
            return elems.toOwnedSlice();
        } else if (eql(word, "comment")) {
            while (true) {
                var b = read.readByte() catch |err| switch (err) {
                    error.EndOfStream => return error.FormatInvalid,
                    else => |e| return e,
                };
                if (b == '\n') {
                    break;
                }
            }
        } else if (eql(word, "element")) {
            try elems.append(try Element.parseDefinition(allocator, read));
        } else if (eql(word, "property")) {
            const last_properties = &elems.items[elems.items.len - 1].properties;

            try last_properties.append(try Property.parseDefinition(allocator, read));
        } else {
            return error.FormatInvalid;
        }
    }
}
