+++
title = "We have Traits at Home"
date = 2026-10-03
authors = ["Axel Magnuson"]
draft = true

[taxonomies]
tags = ["zig", "traits", "polymorphism", "abstraction"]
+++

I have had more time recently to write code in Zig, and it has been good for my
soul.  I wanted to share some insights I have arrived at regarding abstractions
in Zig, including some techniques that I have found useful but not seen
employed more broadly.

Considerable[^seguin2023] ink[^figuratively] has[^wong2025] been[^mckay2025]
spilled[^cypert2026] on Zig Interfaces, and justifiably so.  While not a
language feature, interfaces are the de-facto way of implementing runtime
polymorphism in Zig. Yet[^kelley2021] more[^redig2025] has been said about
zig's comptime, and how it may be leveraged to avoid the performance woes of
dynamic dispatch and write slick, data-oriented code.

To put it briefly, polymorphism in Zig is conventionally obtained in one of two
ways:

2. **Dynamic Interfaces**: Use opaque pointers, virtual tables, and dynamic
   dispatch to achieve runtime polymorphism.
1. **Comptime Duck Typing**: Use type reflection, switch statements, and
   monomorphism at compile time to achieve static polymorhpism.

This state of affairs has proven to be quite effective so far, but it is not
without its tradeoffs.

Interfaces offer the sort of type contracts that we are used to from other
languages.  A function that accepts an interface has a guarantee of its method
signatures, but not its implementation. However because interfaces are, by
design, modular at runtime, they also introduce a hard barrier for the compiler
and thus a performance overhead. There is enough indirection that it often
cannot effectively apply the optimizations that it would to monomorphic code.

For cases of performance critical code, Zig code typically relies on comptime
duck typing.  A function argument is either `anytype` or parameterized by a
type argument `T`, and the function implementation will either perform
compile-time reflection or make assumptions about the type's methods that can
be checked at compile-time.  Implementations can then be monomorphised, similar
to C++ templating or C macros.  This is slightly more safe than runtime duck
typing, because any interface violations will be caught at compile time rather
than runtime, but the caller and callee must still be careful to document and
follow the contract of what types may be passed.

This has worked fine so far.

If you are coming from another strongly typed language, you would be forgiven
for finding this state of affairs rather simplistic. This is perhaps by design
-- Zig aims to be simple.  However if you have grown accustomed to Rust's traits or
Haskell typeclasses, there appears to be no ready equivalent in Zig. I will
argue that, with a little adaptation, Rust's traits and Ocaml's modules can in
fact be expressed perfectly elegantly in Zig userland.

I would like to put forward a new **convention** for defining type contracts as
**Traits** in Zig.  It doesn't require any libraries or machinery - in fact if
fits remarkably well into vanilla Zig.  It is inspired by the functional
programming world in general, and OCaml in particular.

So as not to bury the lead, let me begin with a brief example.

```zig

/// Trait for numeric types, containing arithmetic functions.
fn Num(T: type) type {
    return struct {
        add: fn(T, T) T,
        mul: fn(T, T) T,
        // ... (sub, div)
    }
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
    denominator: u32,

    fn add(lhs: Rational, rhs: Rational) Rational {
        var numerator = lhs.numerator * rhs.denominator + rhs.numerator * lhs.denominator;
        var denominator = rhs.denominator * lhs.denominator;
        // simplify
        while ()
    }
};


```

[^figuratively]: figuratively

[^seguin2023]: [Zig Interfaces](https://www.openmymind.net/Zig-Interfaces/)
by Karl Seguin

[^wong2025]: [Zig Interface
Revisited](https://williamw520.github.io/2025/07/13/zig-interface-revisited.html)
by William Wong

[^mckay2025]: [Inside Zig's new
Writer](https://joegm.github.io/blog/inside-zigs-new-writer-interface/) by Joe
McKay

[^frei2022]: [Zig
Interfaces](https://ethanfrei.com/posts/zig-interfaces.html) by Ethan Frei

[^cypert2026]: [Interfaces in
Zig](https://www.bradcypert.com/interfaces-in-zig/) by Brad Cypert

[^kelley2021]: [A Practical Guide to Applying Data-Oriented
Design](https://vimeo.com/649009599) by Andrew Kelley

[^redig2025]: [Zig Comptime is Bonkers
Good](https://www.scottredig.com/blog/bonkers_comptime/) by Scott Redit


## Conventional Polymorphism

### Comptime Duck Typing

### Interfaces
