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

fn Monad(F: fn (type) type) type {
    return struct {
        pure: Pure,
        flatMap: FlatMap,

        const Pure = @TypeOf(struct {
            fn pure(A: type, a: A) F(A) {
                _ = a;
                unreachable;
            }
        }.pure);

        const FlatMap = @TypeOf(struct {
            fn flatMap(A: type, B: type, fa: F(A), f: fn (A) F(B)) F(B) {
                _ = fa;
                _ = f;
                unreachable;
            }
        }.flatMap);
    };
}

fn Maybe(T: type) type {
    const monad_impl = impl(Monad(Maybe), struct {
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

    return union(enum) {
        nothing,
        just: T,

        const monad = monad_impl;
    };
}

fn Either(A: type, B: type) type {
    const EitherA = struct {
        fn F(B_: type) type {
            return Either(A, B_);
        }

        fn pure(B_: type, b: B_) F(B_) {
            return .{ .right = b };
        }

        fn flatMap(B_: type, C: type, fb: F(B_), f: fn (B_) F(C)) F(C) {
            return switch (fb) {
                .left => |a| .{ .left = a },
                .right => |b| f(b),
            };
        }
    };

    return union(enum) {
        left: A,
        right: B,

        const F = EitherA.F;

        const monad = Monad(F){
            .pure = EitherA.pure,
            .flatMap = EitherA.flatMap,
        };
    };
}

fn chain(
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

fn parseMaybe(s: []const u8) Maybe(i32) {
    return if (std.fmt.parseInt(i32, s, 10)) |value|
        .{ .just = value }
    else |_|
        .nothing;
}

fn invertMaybe(x: i32) Maybe(f32) {
    return if (x == 0)
        .nothing
    else
        .{ .just = 1 / @as(f32, @floatFromInt(x)) };
}

fn chainMaybe(x: []const u8) Maybe(f32) {
    return chain(
        Maybe,
        []const u8,
        i32,
        f32,
        Maybe(undefined).monad,
        x,
        parseMaybe,
        invertMaybe,
    );
}

fn parseEither(s: []const u8) Either(anyerror, i32) {
    return if (std.fmt.parseInt(i32, s, 10)) |value|
        .{ .right = value }
    else |err|
        .{ .left = err };
}

fn invertEither(x: i32) Either(anyerror, f32) {
    return if (x == 0)
        .{ .left = error.divide_by_zero }
    else
        .{ .right = 1 / @as(f32, @floatFromInt(x)) };

}

fn chainEither(x: []const u8) Either(anyerror, f32) {
    return chain(
        Either(anyerror, undefined).F,
        []const u8,
        i32,
        f32,
        Either(anyerror, undefined).monad,
        x,
        parseEither,
        invertEither,
    );
}

pub fn main() !void {
    std.debug.print("{any}\n", .{chainMaybe("4")});
    std.debug.print("{any}\n", .{chainMaybe("0")});
    std.debug.print("{any}\n", .{chainMaybe("x")});

    std.debug.print("{any}\n", .{chainEither("4")});
    std.debug.print("{any}\n", .{chainEither("0")});
    std.debug.print("{any}\n", .{chainEither("x")});
}
