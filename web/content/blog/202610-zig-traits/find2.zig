/// Trait: A type T can index values of type V with keys of type K
fn Index(T: type, K: type, V: type) type {
    return struct {
        get: fn (T, K) ?V,
    };
}

/// Trait: A type T has an equality function
fn Equal(T: type) type {
    return struct {
        eql: fn (T, T) bool,
    };
}

/// if a collection can be indexed by contiguous numbers, we can find the index
/// of a value by scanning through indices.
fn find(
    collection: anytype,
    search_value: anytype,
    index_trait: Index(@TypeOf(collection), usize, @TypeOf(search_value)),
    equal_trait: Equal(@TypeOf(search_value)),
) ?usize {
    var i: usize = 0;
    while (index_trait.get(collection, i)) |value| {
        // note: using duck typing here for brevity
        if (equal_trait.eql(search_value, value)) return i;
        i += 1;
    }
    return null;
}

/// a slice of T values can be indexed by usize
fn sliceIndex(T: type) Index([]const T, usize, T) {
    const inner = struct {
        fn get(slice: []const T, idx: usize) ?T {
            return if (idx < slice.len) slice[idx] else null;
        }
    };
    return .{ .get = inner.get };
}

/// a numeric type can have its equality checked trivially
fn numEqual(T: type) Equal(T) {
    const inner = struct {
        fn eql(lhs: T, rhs: T) bool {
            return lhs == rhs;
        }
    };
    return .{ .eql = inner.eql };
}

pub fn main() u8 {
    const str: []const u8 = "the quick brown fox";
    const char: u8 = 'b';
    const idx = find(str, char, sliceIndex(u8), numEqual(u8));
    return @intCast(idx.?);
}
