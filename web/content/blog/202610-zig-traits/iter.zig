const std = @import("std");

/// a trait that declares T to be iterable over Elem
pub fn Iter(T: type, Elem: type) type {
    return struct {
        next: fn (T) ?Elem,
    };
}

/// a trait that declares T to have an equality function
pub fn Eq(T: type) type {
    return struct {
        eq: fn (T, T) bool,
    };
}

/// find the index of an element in a collection
pub fn find(
    collection: anytype,
    item: anytype,
    comptime traits: struct {
        iter: Iter(@TypeOf(collection), @TypeOf(item)),
        eq: Eq(@TypeOf(item)),
    },
) ?usize {
    var idx: usize = 0;
    while (traits.iter.next(collection)) |elem| : (idx += 1) {
        if (traits.eq.eq(item, elem)) return idx;
    }
    return null;
}

/// find the index of an element in a collection
pub fn find2(T: type, E: type, collection: T, item: E, iter: Iter(T, E), eq: Eq(E)) ?usize {
    var idx: usize = 0;
    while (iter.next(collection)) |elem| : (idx += 1) {
        if (eq.eq(item, elem)) return idx;
    }
    return null;
}

const CaseInsensitiveFindStr = struct {
    index: usize,
    strings: std.ArrayList([]const u8),

    const Self = @This();

    const traits = struct {
        const iter: Iter(*Self, []const u8) = .{ .next = next };
        const eq: Eq([]const u8) = .{ .eq = case_insensitive_eq };
    };

    pub fn find_str(self: *Self, search_str: []const u8) ?usize {
        return find(self, search_str, .{ .iter = traits.iter, .eq = traits.eq });
    }

    fn next(self: *Self) ?[]const u8 {
        if (self.index < self.strings.items.len) {
            defer self.index += 1;
            return self.strings.items[self.index];
        }
        return null;
    }

    fn case_insensitive_eq(lhs: []const u8, rhs: []const u8) bool {
        const toLower = std.ascii.toLower;
        if (lhs.len != rhs.len) return false;
        for (lhs, rhs) |lchar, rchar| {
            if (toLower(lchar) != toLower(rchar)) return false;
        }
        return true;
    }
};

test "CaseInsensitiveFindStr" {
    var list: std.ArrayList([]const u8) = .empty;
    defer list.deinit(std.testing.allocator);
    try list.append(std.testing.allocator, "Foo");
    try list.append(std.testing.allocator, "Bar");
    try list.append(std.testing.allocator, "BAZ");

    var searcher = CaseInsensitiveFindStr{
        .index = 0,
        .strings = list,
    };

    try std.testing.expectEqual(@as(?usize, 1), searcher.find_str("bar"));

    searcher.index = 0;
    try std.testing.expectEqual(@as(?usize, 2), searcher.find_str("baz"));

    searcher.index = 0;
    try std.testing.expectEqual(@as(?usize, null), searcher.find_str("qux"));
}
