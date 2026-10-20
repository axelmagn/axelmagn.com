/// Trait for numeric types, containing arithmetic functions.
fn Num(T: type) type {
    return struct {
        add: fn (T, T) T,
        sub: fn (T, T) T,
        mul: fn (T, T) T,
        div: fn (T, T) T,
    };
}

fn default_num(T: type) Num(T) {
    const inner = struct {
        fn add(lhs: T, rhs: T) T {
            return lhs + rhs;
        }
        fn sub(lhs: T, rhs: T) T {
            return lhs - rhs;
        }
        fn mul(lhs: T, rhs: T) T {
            return lhs * rhs;
        }
    };
    const div = switch (@typeInfo(T)) {
        .int, .comptime_int => struct {
            fn div(lhs: T, rhs: T) T {
                return @divTrunc(lhs, rhs);
            }
        }.div,
        .float, .comptime_float => struct {
            fn div(lhs: T, rhs: T) T {
                return lhs / rhs;
            }
        }.div,
        else => @compileError("unsupported type: " ++ @typeName(T)),
    };
    return .{ .add = inner.add, .sub = inner.sub, .mul = inner.mul, .div = div };
}

const Complex = struct {
    real: f32,
    imag: f32,

    const num: Num(Complex) = .{ .add = add, .mul = mul };

    fn add(lhs: Complex, rhs: Complex) Complex {
        return .{ .real = lhs.real + rhs.real, .imag = lhs.imag + rhs.imag };
    }

    fn mul(lhs: Complex, rhs: Complex) Complex {
        const a = lhs.real;
        const b = lhs.imag;
        const c = rhs.real;
        const d = rhs.imag;
        return .{ .real = a * c - b * d, .imag = a * d + b * c };
    }
};

const Rational = struct {
    numerator: i32,
    denominator: i32,

    const num: Num(Rational) = .{ .add = add, .mul = mul };

    fn add(lhs: Rational, rhs: Rational) Rational {
        const numerator = lhs.numerator * rhs.denominator + rhs.numerator * lhs.denominator;
        const denominator = rhs.denominator * lhs.denominator;
        return simplify(numerator, denominator);
    }

    fn mul(lhs: Rational, rhs: Rational) Rational {
        const numerator = lhs.numerator * rhs.numerator;
        const denominator = rhs.denominator * lhs.denominator;
        return simplify(numerator, denominator);
    }

    fn simplify(numerator: i32, denominator: i32) Rational {
        var i: i32 = 2;
        var numer = numerator;
        var denom = denominator;
        // simplify
        while (i < @abs(denom) and i < @abs(numer)) {
            if (@mod(numer, i) == 0 and @mod(denom, i) == 0) {
                numer = @divExact(numer, i);
                denom = @divExact(denom, i);
            }
            i += 1;
        }
        return .{ .numerator = numer, .denominator = denom };
    }
};

fn square(T: type, value: T, num_trait: Num(T)) T {
    return num_trait.mul(value, value);
}

fn square_any(value: anytype, num_trait: Num(@TypeOf(value))) @TypeOf(value) {
    return square(@TypeOf(value), value, num_trait);
}

pub fn main() void {
    const std = @import("std");

    const a = Complex{ .real = 0, .imag = 1 };
    std.debug.print("{any}^2 = {any}\n", .{ a, square(Complex, a, Complex.num) });
    const b = Rational{ .numerator = 2, .denominator = 3 };
    std.debug.print("{any}^2 = {any}\n", .{ b, square_any(b, Rational.num) });
}

fn mobius(
    comptime T: type,
    comptime add: fn (T, T) T,
    comptime mul: fn (T, T) T,
    comptime div: fn (T, T) T,
    x: T,
    a: T,
    b: T,
    c: T,
    d: T,
) T {
    const numerator = add(mul(a, x), b);
    const denominator = add(mul(c, x), d);
    return div(numerator, denominator);
}

test {
    mobius(Complex, Complex.add, Complex.mul, Complex.div, x, a, b, c, d);
    mobius(Real, Real.add, Real.mul, Real.div, x, a, b, c, d);
}

fn getTrait(Trait: type, Impl: type) ?Trait {
    comptime {
        // first, try to find the trait declared explicitly as a member
        for (@typeInfo(Impl).@"struct".decl_names) |decl_name| {
            if (@TypeOf(@field(Impl, decl_name)) == Trait) {
                return @field(Impl, decl_name);
            }
        }
        // if that fails, try to construct the trait from declarations
        var result: Trait = undefined;
        var success = true;
        for (
            @typeInfo(Trait).@"struct".field_names,
            @typeInfo(Trait).@"struct".field_types,
        ) |field_name, field_type| {
            if (!@hasDecl(Impl, field_name) or
                field_type != @TypeOf(@field(Impl, field_name)))
            {
                success = false;
                break;
            }
            @field(result, field_name) = @field(Impl, field_name);
        }
        if (success) {
            return result;
        }

        return null;
    }
}
