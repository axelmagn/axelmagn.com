const std = @import("std");

fn impl(comptime Sig: type, comptime M: type) Sig {
    comptime {
        var result: Sig = undefined;
        for (@typeInfo(Sig).@"struct".field_names) |field_name| {
            if (!@hasDecl(M, field_name)) @compileError(@typeName(M) ++ " is missing `" ++ field_name ++ "`");
            @field(result, field_name) = @field(M, field_name);
        }
        return result;
    }
}

fn Monad(M: fn (type) type) type {
    return struct {
        pure: Pure,
        flatMap: FlatMap,

        const Pure = @TypeOf(struct {
            fn pure(A: type, a: A) M(A) {
                _ = a;
                unreachable;
            }
        }.pure);

        const FlatMap = @TypeOf(struct {
            fn flatMap(A: type, B: type, value: M(A), f: fn (A) M(B)) M(B) {
                _ = value;
                _ = f;
                unreachable;
            }
        }.flatMap);
    };
}

fn Maybe(T: type) type {
    return union(enum) {
        nothing,
        just: T,

        const monad = maybe_monad;
    };
}

const maybe_monad = impl(Monad(Maybe), struct {
    pub fn pure(A: type, a: A) Maybe(A) {
        return .{ .just = a };
    }

    pub fn flatMap(
        A: type,
        B: type,
        fa: Maybe(A),
        f: fn (A) Maybe(B),
    ) Maybe(B) {
        return switch (fa) {
            .nothing => .nothing,
            .just => |a| f(a),
        };
    }
});

fn Either(A: type, B: type) type {
    return union(enum) {
        left: A,
        right: B,

        const EitherA = struct {
            fn F(B_: type) type {
                return Either(A, B_);
            }
        }.F;

        const monad = impl(Monad(EitherA), struct {
            pub fn pure(B_: type, b: B_) EitherA(B_) {
                return .{ .right = b };
            }

            pub fn flatMap(
                B_: type,
                C: type,
                fb: EitherA(B_),
                f: fn (B_) EitherA(C),
            ) EitherA(C) {
                return switch (fb) {
                    .left => |a| .{ .left = a },
                    .right => |b| f(b),
                };
            }
        });
    };
}

fn chain2(
    M: fn (type) type,
    A: type,
    B: type,
    C: type,
    monad: Monad(M),
    x: A,
    f: fn (A) M(B),
    g: fn (B) M(C),
) M(C) {
    const start = monad.pure(A, x);
    const y: M(B) = monad.flatMap(A, B, start, f);
    const z: M(C) = monad.flatMap(B, C, y, g);
    return z;
}
fn ParseInvert(T: fn (type) type) type {
    return struct {
        parse: fn ([]const u8) T(i32),
        invert: fn (i32) T(f32),
        monad: Monad(T),

        fn chain(self: @This(), value: []const u8) T(f32) {
            return chain2(
                T,
                []const u8,
                i32,
                f32,
                self.monad,
                value,
                self.parse,
                self.invert,
            );
        }
    };
}

const maybe_parse_invert = impl(ParseInvert(Maybe), struct {
    pub fn parse(s: []const u8) Maybe(i32) {
        return if (std.fmt.parseInt(i32, s, 10)) |value|
            .{ .just = value }
        else |_|
            .nothing;
    }

    pub fn invert(x: i32) Maybe(f32) {
        return if (x == 0)
            .nothing
        else
            .{ .just = 1 / @as(f32, @floatFromInt(x)) };
    }

    pub const monad = Maybe(undefined).monad;
});

const EitherErr = Either(anyerror, undefined).EitherA;

const either_parse_invert = impl(ParseInvert(EitherErr), struct {
    pub fn parse(s: []const u8) EitherErr(i32) {
        return if (std.fmt.parseInt(i32, s, 10)) |value|
            .{ .right = value }
        else |err|
            .{ .left = err };
    }

    pub fn invert(x: i32) EitherErr(f32) {
        return if (x == 0)
            .{ .left = error.divide_by_zero }
        else
            .{ .right = 1 / @as(f32, @floatFromInt(x)) };
    }

    pub const monad = EitherErr(undefined).monad;
});

pub fn main() !void {
    std.debug.print("{any}\n", .{maybe_parse_invert.chain("4")});
    std.debug.print("{any}\n", .{maybe_parse_invert.chain("0")});
    std.debug.print("{any}\n", .{maybe_parse_invert.chain("x")});

    std.debug.print("\n", .{});

    std.debug.print("{any}\n", .{either_parse_invert.chain("4")});
    std.debug.print("{any}\n", .{either_parse_invert.chain("0")});
    std.debug.print("{any}\n", .{either_parse_invert.chain("x")});
}
