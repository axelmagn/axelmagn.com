/// Trait for numeric types, containing arithmetic functions.
fn Num(T: type) type {
    return struct {
        add: fn (T, T) T,
        mul: fn (T, T) T,
        // ... (sub, div)
    };
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
