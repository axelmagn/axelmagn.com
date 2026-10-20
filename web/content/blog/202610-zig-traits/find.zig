/// Trait: A type T can index values of type V with keys of type K
fn Index(T: type, K: type, V: type) type {
    return struct {
        get: fn (T, K) ?V,
    };
}

/// if a collection can be indexed by contiguous numbers, we can find the index
/// of a value by scanning through indices.
fn find(
    collection: anytype,
    search_value: anytype,
    index_trait: Index(@TypeOf(collection), usize, @TypeOf(search_value)),
) ?usize {
    var i: usize = 0;
    while (index_trait.get(collection, i)) |value| {
        // note: using duck typing here for brevity
        if (search_value == value) return i;
        i += 1;
    }
    return null;
}

/// a slice of T values can be indexed by usize
fn sliceIndex(T: type) Index([]const T, usize, T) {
    return .{
        .get = struct {
            fn get(slice: []const T, idx: usize) ?T {
                return if (idx < slice.len) slice[idx] else null;
            }
        }.get,
    };
}

pub fn main() u8 {
    const str: []const u8 = "the quick brown fox";
    const char: u8 = 'b';
    const trait = sliceIndex(u8);
    const idx = find(str, char, trait);
    return @intCast(idx.?);
}
