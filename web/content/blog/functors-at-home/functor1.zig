const std = @import("std");

// fn Functor(F: fn (type) type) type {
//     return struct {
//         fmap: fn(A: type, B: type) fn(fn(A) B, F(A)) F(B),
//     };
// }

fn Maybe(T: type) type {
    return union(enum) {
        nothing,
        just: T,
    };
}

fn fmapMaybe(A: type, B: type, f: fn (A) B, maybe: Maybe(A)) Maybe(B) {
    return switch (maybe) {
        .nothing => .nothing,
        .just => |val| .{ .just = f(val) },
    };
}

fn add(a: i32, b: i32) i64 {
    return a + b;
}

fn addTwo(T: type, x: T) T {
    return x + 2;
}

fn describe(comptime name: []const u8, comptime F: type) void {
    const info = @typeInfo(F).@"fn";

    std.debug.print("{s}: {s}\n", .{ name, @typeName(F) });

    inline for (info.param_types, 0..) |P, i| {
        // null means the parameter is generic (anytype / depends on a comptime arg)
        const p_name: []const u8 = if (P) |T| @typeName(T) else "(generic)";
        std.debug.print("  param {d}: {s}\n", .{ i, p_name });
    }

    const r_name: []const u8 = if (info.return_type) |R| @typeName(R) else "(generic)";
    std.debug.print("  returns: {s}\n", .{r_name});
}

pub fn main() void {
    describe("add", @TypeOf(addTwo));
}
