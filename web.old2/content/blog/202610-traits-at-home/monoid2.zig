fn Monoid(T: type) type {
    return struct {
        empty: T,
        combine: fn (T, T) T,

        fn fold(self: @This(), xs: []const T) T {
            var accum = self.empty;
            for (xs) |x| accum = self.combine(accum, x);
            return accum;
        }
    };
}

fn Sum(T: type) Monoid(T) {
    const inner = struct {
        fn add(x: T, y: T) T { return x + y; }
    };
    return .{ .empty = 0, .combine = inner.add };
}

export fn run(buf: [*c]i32, n: usize) i32 {
    return Sum(i32).fold(buf[0..n]);
}
