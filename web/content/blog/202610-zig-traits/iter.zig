const std = @import("std");

/// a trait that declares T to be iterable over Elem
pub fn Iterator(T: type, Elem: type) type {
    return struct {
        next: fn (T) ?Elem,
    };
}
