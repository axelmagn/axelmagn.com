+++
title = "We Have Monads at Home"
date = 2026-10-30
authors = ["Axel Magnuson"]
draft = true

[taxonomies]
tags = ["zig", "traits", "polymorphism", "abstraction"]
+++

In my previous article, [We Have Traits at Home](../202610-zig-traits/index.md),
I wrote about how to use Zig's comptime machinery to implement abstractions that
imitate modules from Ocaml or traits from Rust.

Traits were directly inspired by functional programming languages. It is
natural, then, to wonder what other ideas from functional programming are
expressible via traits in Zig. As you will see, Zig's comptime and type system
is sufficiently powerful to represent a wide domain of Haskell typeclasses,
including functors, applicatives, and monads. However Zig was not necessarily
built to accomodate these abstractions, and as we venture into the realms of
higher-kinded types, it will require us to commit some crimes against code
aesthetics.

This article will be a catalog and tutorial of how to implement these
typeclasses[^use-haskell-typeclasses] in Zig using traits. Unlike the previous
one, which I think is generally relevant to most Zig users, this is primarily
for the functional programmers and type system enthusiasts among you. We're
going to indulge our inner functional programmers and get a little niche.

[^use-haskell-typeclasses]:
    In general this article will choose traits that correspond to Haskell
    typeclasses. Of the various functional languages we could use, Haskell is
    both terse and powerful enough to express higher-kinded types. However this
    choice is still fairly arbitrary.

## Decoupling Data From Functions

Before we dive into the muck, let me speak for a moment on the coupling between
functions and data. I find it generally useful to think of my programs in terms
of just data, and functions that operate on that data. It cuts through a lot of
language-specific and paradigm-specific confusion. I love Zig's comptime
features because they allow me to think of types as simply another kind of data
I might need to transform with functions.

However one of the more pernicious harms of OOP is how it has rewired everyone's
brains to zealously couple methods to data. Even in languages such as Zig, which
eschews OOP, we still have the facilities to declare "methods" on structs. I
fear that for programmers who have already written a lot of object oriented
code, it is too easy to treat this facility as an obligation. It can feel
_unergonomic_ to call a function that is not preceded by a dot accessor, and yet
that is what I am going to ask you to do.

Zig took the OOP concept of an interface, and implemented it in userland to
solve the runtime abstraction problem. It said "well, other languages implement
interfaces as VTables and opaque pointers, so let's just make that explicit." I
don't have any beef with that. In fact, I can't think of a better way to solve
that particular problem. However in the general case, I think we can do better.

Instead, let's think in terms of just **data**, **types**, and **functions**
that transform those data or types. When I declare a trait in Rust or a module
signature in OCaml, I am really declaring a type that contains a set of
functions, made generic over a type that has not yet been specified. Then an
implementation is a value of this type. Both the trait/signature and the
implementation are available at comptime. Thankfully, Zig already has facilities
for all of this.

## Simple Traits

A lot of people in the comments of my previous article wanted more examples of
how traits could be useful. Before getting too advanced, let's start with some
more basic, everyday traits that we could use to declare common interfaces.

### Show

Suppose that you want to convert a value to a string. Zig's default facility to
handle this is to declare a `format` function inside of your struct, which takes
a writer as an argument and is accessed via duck typing as part of a call to
print. This allows the writer to abstract away memory allocation, so that the
format function can focus on how to display a value.

```zig
pub fn format(self: *const T, writer: *Writer,) !void {
    try writer.print( ... );
}
```

This works perfectly fine, but how would we implement the equivalent as a trait?
The equivalent in Haskell would be the `Show` typeclass.

```haskell
class Show a where
    show :: a -> String
```

We can implement the equivalent in zig. Returning strings in Zig is fraught with
allocation, so let's assume that we are printing to a buffer in the style of
[`std.mem.print`](https://ziglang.org/documentation/0.17.0/std/#std.mem.print).
[^trait-helpers-appendix]

[^trait-helpers-appendix]:
    This article will make use of the trait helper functions from the first
    article, reproduced in [Appendix A](@#appendix-a-trait-helpers).

```zig
pub fn Show(T: type) type {
    return struct {
        show: fn (self: *const T, buf: []u8) ShowError![]u8,
    };
}
pub const ShowError = std.mem.PrintError;

// example usage
fn printMyThing(T: type, value: *const T) !void {
    var buf: [64]u8 = undefined;
    const value_str = try getTrait(Show(T), T).show(value, &buf);
    std.debug.print("my {s}: {s}\n", .{ @typeName(T), value_str });
}
```

## Eq and Ord

Another fundamental need is to be able to compare two values in a type. For
this, it is common to have an equality comparator, and an ordering comparator.
In Haskell the equivalent typeclasses are `Eq` and `Ord`.

```haskell
class  Eq a  where
    (==), (/=)           :: a -> a -> Bool
    ...

class  (Eq a) => Ord a  where
    compare              :: a -> a -> Ordering
    ...
```

In this case, `Ord` requires `Eq`. We can straightforwardly translate this
requirement to Zig traits by bundling the equality trait inside of the `Ord`
implementation.

```zig
pub fn Eq(T: type) type {
    return struct {
        eq: fn (T, T) bool,
    };
}

pub fn Ord(T: type) type {
    return struct {
        cmp: fn (T, T) std.math.Order,
        eq_trait: Eq(T),
    };
}
```

A good use case for this would be if we wanted a case insensitive ordering on
strings, which we could implement as follows.[^ord-godbolt]

[^ord-godbolt]: [full sorting example](https://godbolt.org/z/vxGch13er)

```zig
const StringOrd = Ord([]const u8);
pub const case_insensitive_ord = impl(StringOrd, struct {
    pub fn cmp(lhs: []const u8, rhs: []const u8) std.math.Order {
        const toLower = std.ascii.toLower;
        const len = @max(lhs.len, rhs.len);
        for (0..len) |i| {
            const lhs_char = if (i < lhs.len) toLower(lhs[i]) else 0;
            const rhs_char = if (i < rhs.len) toLower(rhs[i]) else 0;
            if (lhs_char < rhs_char) return .lt;
            if (lhs_char > rhs_char) return .gt;
        }
        return .eq;
    }

    pub const eq_trait: Eq([]const u8) = impl(Eq([]const u8), struct {
        pub fn eq(lhs: []const u8, rhs: []const u8) bool {
            return cmp(lhs, rhs) == .eq;
        }
    });
});
```

## Appendix A: Trait Helpers

We use the following trait helpers, introduced in the previous article, to make
trait definition and retrieval more convenient.

```zig
pub fn impl(comptime Trait: type, comptime Impl: type) Trait {
    comptime {
        var result: Trait = undefined;
        for (@typeInfo(Trait).@"struct".field_names) |field_name| {
            @field(result, field_name) = @field(Impl, field_name);
        }
        return result;
    }
}

pub fn getTrait(Trait: type, Impl: type) Trait {
    comptime {
        // try to find the trait declared explicitly as a member
        for (@typeInfo(Impl).@"struct".decl_names) |decl_name| {
            if (@TypeOf(@field(Impl, decl_name)) == Trait) {
                return @field(Impl, decl_name);
            }
        }
        // otherwise throw an error
        @compileError("trait " ++ @typeName(Trait) ++ " not found on " ++ @typeName(Impl));
    }
}
```
