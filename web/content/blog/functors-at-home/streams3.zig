const std = @import("std");

fn Stream(T: type, V: type) type {
    return struct {
        next: fn (*T) ?V,

        fn map(stream: @This(), Out: type, f: fn (V) Out) Stream(T, Out) {
            return .{ .next = struct {
                fn next(self: *T) ?Out {
                    return if (stream.next(self)) |value| f(value) else null;
                }
            }.next };
        }

        fn filter(stream: @This(), f: fn (V) bool) Stream(T, V) {
            return .{ .next = struct {
                fn next(self: *T) ?V {
                    while (stream.next(self)) |value| {
                        if (f(value)) return value;
                    }
                    return null;
                }
            }.next };
        }

        fn reduce(
            stream: @This(),
            Out: type,
            self: *T,
            init: Out,
            f: fn (Out, V) Out,
        ) Out {
            var accum = init;
            while (stream.next(self)) |value| {
                accum = f(accum, value);
            }
            return accum;
        }
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
    const funcs = struct {
        fn odd(x: i64) bool {
            return @mod(x, 2) == 1;
        }
        fn half(x: i64) f64 {
            return @as(f64, @floatFromInt(x)) / 2;
        }
        fn sum(x: f64, y: f64) f64 {
            return x + y;
        }
    };

    var range = StepRange{ .current = 2, .end = 15, .step = 3 };
    const result = StepRange.stream         // 2, 5, 8, 11, 14
        .filter(funcs.odd)                  // -> 5, 11
        .map(f64, funcs.half)               // -> 2.5, 5.5
        .reduce(f64, &range, 0, funcs.sum); // -> 8
    std.debug.print("{d}\n", .{result}); 
}
