const std = @import("std");

pub fn Eq(T: type) type {
    return struct {
        eq: fn (T, T) bool,
    };
}

pub fn Ord(T: type) type {
    return struct {
        cmp: fn (T, T) std.math.Order,
        eq_trait: Eq(T),

        pub fn asc(comptime self: Ord(T)) fn (void, T, T) bool {
            return struct {
                pub fn f(_: void, lhs: T, rhs: T) bool {
                    return self.cmp(lhs, rhs) == .lt;
                }
            }.f;
        }
    };
}

const StringOrd = Ord([]const u8);
pub const case_insensitive_ord = impl(StringOrd, struct {
    pub fn cmp(lhs: []const u8, rhs: []const u8) std.math.Order {
        const toLower = std.ascii.toLower;
        const len = @max(lhs.len, rhs.len);
        for (0..len) |i| {
            const lhs_char = if (i < lhs.len) toLower(lhs[i]) else 0;
            const rhs_char = if (i < rhs.len) toLower(rhs[i]) else 0;
            if (lhs_char < rhs_char) return .lt;
            if (lhs_char > rhs_char) return .gt;
        }
        return .eq;
    }

    pub const eq_trait: Eq([]const u8) = impl(Eq([]const u8), struct {
        pub fn eq(lhs: []const u8, rhs: []const u8) bool {
            return cmp(lhs, rhs) == .eq;
        }
    });
});

pub fn main() !void {
    const strs: []const []const u8 = &.{ "foo", "bar", "baz", "FOO", "BAR", "BAZ" };
    var buf: [64][]const u8 = undefined;
    const slice: [][]const u8 = buf[0..strs.len];
    @memcpy(slice, strs);
    std.mem.sort([]const u8, slice, {}, case_insensitive_ord.asc());
    for (slice) |s| {
        std.debug.print("{s}\n", .{s});
    }
}

pub fn impl(comptime Trait: type, comptime Impl: type) Trait {
    comptime {
        var result: Trait = undefined;
        for (@typeInfo(Trait).@"struct".field_names) |field_name| {
            @field(result, field_name) = @field(Impl, field_name);
        }
        return result;
    }
}

pub fn getTrait(Trait: type, Impl: type) Trait {
    comptime {
        // try to find the trait declared explicitly as a member
        for (@typeInfo(Impl).@"struct".decl_names) |decl_name| {
            if (@TypeOf(@field(Impl, decl_name)) == Trait) {
                return @field(Impl, decl_name);
            }
        }
        // otherwise throw an error
        @compileError("trait " ++ @typeName(Trait) ++ " not found on " ++ @typeName(Impl));
    }
}
