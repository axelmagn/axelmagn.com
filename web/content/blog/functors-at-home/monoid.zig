fn Monoid(T: type) type {
    return struct {
        empty: T,
        combine: fn (T, T) T,
    };

}

fn Sum(T: type) Monoid(T) {
    const inner = struct {
        fn add(x: T, y: T) T { return x + y; }
    };
    return .{ .empty = 0, .combine = inner.add };
}

fn fold(T: type, xs: []const T, m: Monoid(T)) T {
    var accum = m.empty;
    for (xs) |x| accum = m.combine(accum, x);
    return accum;
}

export fn run(buf: [*c]i32, n: usize) i32 {
    return fold(i32, buf[0..n], Sum(i32));
}
