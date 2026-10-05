const std = @import("std");

fn Functor(F: fn (type) type) type {
    return struct {
        // fn(A, B, f(A) B, F(A)) F(B)
        fmap: FMap,

        const FMap = @TypeOf(struct {
            fn fmap(A: type, B: type, f: fn (A) B, x: F(A)) F(B) {
                _ = f;
                _ = x;
                unreachable;
            }
        }.fmap);
    };
}

fn Maybe(T: type) type {
    const functor_impl = impl(Functor(Maybe), struct {
        pub fn fmap(A: type, B: type, f: fn (A) B, maybe: Maybe(A)) Maybe(B) {
            return switch (maybe) {
                .nothing => .nothing,
                .just => |val| .{ .just = f(val) },
            };
        }
    });
    return union(enum) {
        nothing,
        just: T,

        const functor = functor_impl;
    };
}

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

fn addTwoPointFive(x: i32) f32 {
    return @as(f32, @floatFromInt(x)) + 2.5;
}

fn Buf8(T: type) type {
    const functor_impl = impl(Functor(Buf8), struct {
        pub fn fmap(A: type, B: type, f: fn (A) B, xs: Buf8(A)) Buf8(B) {
            var out: Buf8(B) = undefined;
            for (0.., xs.buf) |i, x| {
                out.buf[i] = f(x);
            }
            return out;
        }
    });

    return struct {
        buf: [8]T = undefined,
        const functor = functor_impl;
    };
}

fn Buf4(T: type) type {
    const functor_impl = impl(Functor(Buf4), struct {
        pub fn fmap(A: type, B: type, f: fn (A) B, xs: Buf4(A)) Buf4(B) {
            var out: Buf4(B) = undefined;
            for (0.., xs.buf) |i, x| {
                out.buf[i] = f(x);
            }
            return out;
        }
    });

    return struct {
        buf: [4]T = undefined,
        const functor = functor_impl;
    };
}

fn withResult(
    A: type,
    B: type,
    F: fn (type) type,
    functor: Functor(F),
    mapper: fn (A) B,
    xs: F(A),
) F(struct { A, B }) {
    const f = struct {
        fn f(x: A) struct { A, B } {
            return .{ x, mapper(x) };
        }
    }.f;
    return functor.fmap(A, struct { A, B }, f, xs);
}

pub fn main() void {
    const a = Buf4(i32){ .buf = .{ 1, 2, 3, 4 } };
    const b = Buf4(undefined).functor.fmap(i32, f32, addTwoPointFive, a);
    std.debug.print("{any}\n", .{b});
    const c = withResult(i32, f32, Buf4, Buf4(undefined).functor, addTwoPointFive, a);
    std.debug.print("{any}\n", .{c});
}
