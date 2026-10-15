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
            while(stream.next(self)) |value| {
                accum = f(accum, value);
            }
            return accum;
        }

        /// collect the outputs of a stream into a buffer and return number collected
        fn collect(stream: @This(), self: *T, out: []V) usize {
            for (0..out.len) |i| {
                const value = stream.next(self);
                if (value == null) return i;
                out[i] = value.?;
            }
            return out.len;
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

fn BufIter(T: type) type {
    return struct {
        buf: []T,
        idx: usize = 0,

        const stream: Stream(@This(), T) = .{ .next = next };

        fn next(self: *@This()) ?T {
            if (self.idx < self.buf.len) {
                defer self.idx += 1;
                return self.buf[self.idx];
            }
            return null;
        }
    };
}

pub fn main() void {
    var range = StepRange.new(2, 32, 3);
    var buf: [32]f64 = undefined;

    const funcs = struct {
        fn odd(x: i64) bool {
            return @mod(x, 2) == 1;
        }
        fn half(x: i64) f64 {
            return @as(f64, @floatFromInt(x)) / 2;
        }
    };

    // const stream = StepRange.stream.filter(funcs.odd).map(f64, funcs.half);
    const stream = StepRange.stream.filter(funcs.odd).map(f64, funcs.half);
    const n = stream.collect(&range, &buf);

    var sum: f64 = 0;
    for (0..n) |i| {
        sum += buf[i];
    }
    return sum;
}
