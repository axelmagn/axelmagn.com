const std = @import("std");

fn Stream(T: type, V: type) type {
    return struct {
        next: fn (*T) ?V,
    };
}

const StepRange = struct {
    current: i64,
    end: i64,
    step: i64,

    const stream: Stream(StepRange, i64) = .{ .next = next };

    fn next(self: *StepRange) ?i64 {
        if (self.current < self.end) {
            defer self.current += self.step;
            return self.current;
        }
        return null;
    }
};

pub fn main() void {
    var range = StepRange{ .current = 2, .end = 15, .step = 3 };
    while (StepRange.stream.next(&range)) |value| {
        std.debug.print("{d}\n", .{value});
    }
}
