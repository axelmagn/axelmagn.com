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
    return union(enum) {
        nothing,
        just: T,
    };
}

// fn fmapMaybe(A: type, B: type, f: fn (A) B, maybe: Maybe(A)) Maybe(B) {
//     return switch (maybe) {
//         .nothing => .nothing,
//         .just => |val| .{ .just = f(val) },
//     };
// }

// const MaybeFunctor = Functor(Maybe){
//     .fmap = struct {
//         fn fmap(A: type, B: type, f: fn (A) B, maybe: Maybe(A)) Maybe(B) {
//             return switch (maybe) {
//                 .nothing => .nothing,
//                 .just => |val| .{ .just = f(val) },
//             };
//         }
//     }.fmap,
// };

const maybe_functor = impl(Functor(Maybe), struct {
    pub fn fmap(A: type, B: type, f: fn (A) B, maybe: Maybe(A)) Maybe(B) {
        return switch (maybe) {
            .nothing => .nothing,
            .just => |val| .{ .just = f(val) },
        };
    }
});

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

fn withResult(
    A: type,
    B: type,
    F: fn(type) type,
    functor: Functor(F),
    mapper: fn (A) B,
    xs: F(A),
) F(struct { A, B }) {
    const f = struct {
        fn f(x: A) struct {A, B} {
            return .{ x, mapper(x) };
        }
    }.f;
    return functor.fmap(A, struct {A, B}, f, xs);
}

pub fn main() void {
    const x = Maybe(i32){ .just = 2 };
    const y = maybe_functor.fmap(i32, f32, addTwoPointFive, x);
    std.debug.print("{any} -> {any}\n", .{ x, y });
    const z = withResult(i32, f32, Maybe, maybe_functor, addTwoPointFive, x);
    std.debug.print("{any} -> {any}\n", .{ x, z });
}
