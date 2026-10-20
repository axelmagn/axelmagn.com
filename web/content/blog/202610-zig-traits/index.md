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

If you are coming from another strongly typed language, you would be forgiven
for finding this state of affairs rather simplistic. This is perhaps by design
-- Zig aims to be simple.  However if you have grown accustomed to Rust's traits or
Haskell typeclasses, there appears to be no ready equivalent in Zig. 

I will argue that, with a little adaptation, it is perfectly possible to
express similar abstractions over types in Zig userland. I would propose a new
**convention** for defining compile-time type contracts as **Traits** in Zig.
It doesn't require any libraries or machinery - in fact if fits remarkably well
into vanilla Zig.  It is inspired by the functional programming world in
general, and OCaml in particular.

> **Definition:** a Trait is a compile-time struct which contains related
> functions over a given type.

So as not to bury the lead, let me begin with a brief example.

```zig
/// a trait that declares T to be iterable over Elem
pub fn Iter(T: type, Elem: type) type {
    return struct {
        next: fn (T) ?Elem,
    };
}

/// a trait that declares T to have an equality function
pub fn Eq(T: type) type {
    return struct {
        eq: fn (T, T) bool,
    };
}

/// find the index of an element in a collection
pub fn find(
    collection: anytype,
    item: anytype,
    iter: Iter(@TypeOf(arr), @TypeOf(item)),
    eq: Eq(@TypeOf(item)),
) ?usize {
    var idx: usize = 0;
    while (iter.next(arr)) |elem| : (idx += 1) {
        if (eq.eq(item, elem)) return idx;
    }
    return null;
}
```

To use the find function, a developer simply implements the required traits for
the type they want to use.

```zig
const CaseInsensitiveFindStr = struct {
    index: usize,
    strings: std.ArrayList([]const u8),

    const Self = @This();

    const traits = struct {
        const iter: Iter(*Self, []const u8) = .{ .next = next };
        const eq: Eq([]const u8) = .{ .eq = case_insensitive_eq };
    };

    pub fn find_str(self: *Self, search_str: []const u8) ?usize {
        return find(self, search_str, .{ .iter = traits.iter, .eq = traits.eq });
    }

    fn next(self: *Self) ?[]const u8 {
        if (self.index < self.strings.items.len) {
            defer self.index += 1;
            return self.strings.items[self.index];
        }
        return null;
    }

    fn case_insensitive_eq(lhs: []const u8, rhs: []const u8) bool {
        const toLower = std.ascii.toLower;
        if (lhs.len != rhs.len) return false;
        for (lhs, rhs) |lchar, rchar| {
            if (toLower(lchar) != toLower(rchar)) return false;
        }
        return true;
    }
};
```

If this looks a bit verbose, don't worry.  This article will talk later about
ways we can make traits more ergonomic.  The important thing is that they are a
*userland convention* for defining interfaces and implementations that can be
resolved an monomorphised at comptime.

Traits are just bags of functions and types that tell the receiving function
how to execute subtasks that it's not responsible for defining.  They behave a
lot like vtables, except that they are evaluated at comptime rather than
runtime.


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


## Conventional Polymorphism and Traits

To provide a tour through polymorhpism, let's start with a common motivating
example: arithmetic operations.  I've seen a few complaints over the years
about how awkward is it to do math in Zig over user-defined types.  In its
pursuit of explicit control flow, Zig has eschewed operator overloading.

Let's imagine we have some user-defined types like `Rational` and `Complex`,
and we want to define their basic arithmentic operations.  We would probably
end up with something like the following.

```zig
const Rational = struct {
    numerator: i32,
    denominator: i32,

    fn add(lhs: Rational, rhs: Rational) Rational {...}
    fn sub(lhs: Rational, rhs: Rational) Rational {...}
    fn mul(lhs: Rational, rhs: Rational) Rational {...}
    fn div(lhs: Rational, rhs: Rational) Rational {...}
};

const Complex = struct {
    real: f32,
    imaginary: f32,

    fn add(lhs: Complex, rhs: Complex) Complex {...}
    fn sub(lhs: Complex, rhs: Complex) Complex {...}
    fn mul(lhs: Complex, rhs: Complex) Complex {...}
    fn div(lhs: Complex, rhs: Complex) Complex {...}
};
```

### Comptime Duck Typing

Both user-defined types have pretty similar method signatures, 

### Interfaces
