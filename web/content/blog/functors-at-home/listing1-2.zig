// LISTING 1-2
const Shape = struct {
    ptr: *const anyopaque,
    areaFn: *const fn (*const anyopaque) f64,

    fn area(self: *const Shape) f64 {
        return self.areaFn(self.ptr);
    }
};

const Square = struct {
    side: f64,

    fn shape(self: *const Square) Shape {
        return .{ .ptr = self, .areaFn = area };
    }

    fn area(p: *const anyopaque) f64 {
        const self: *const Square = @ptrCast(@alignCast(p));
        return self.side * self.side;
    }
};

export fn runFast(square: *const Square) f64 {
    return square.shape().area();
}

export fn runSlow(n: usize) f64 {
    var squares: [64]Square = undefined;
    var shapes: [64]Shape = undefined;
    const len = @min(n, 64);
    for (0..len) |i| {
        squares[i] = .{ .side = @floatFromInt(i) };
        shapes[i] = squares[i].shape();
    }
    var total: f64 = 0;
    for (shapes[0..len]) |s| total += s.area();
    return total;
}
