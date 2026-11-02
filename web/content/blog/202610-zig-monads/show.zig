const std = @import("std");
const Writer = std.Io.Writer;

const Car = struct {
    year: u32,
    make: []const u8,
    model: []const u8,

    pub const show_trait: Show(Car) = impl(Show(Car), struct {
        pub fn show(
            self: *const Car,
            buf: []u8,
        ) std.mem.PrintError![]u8 {
            return std.mem.print(
                buf,
                "Car({d} {s} {s})",
                .{ self.year, self.make, self.model },
            );
        }
    });
};

pub fn Show(T: type) type {
    return struct {
        show: fn (self: *const T, buf: []u8) ShowError![]u8,
    };
}
pub const ShowError = std.mem.PrintError;

fn printMyThing(T: type, value: *const T) !void {
    var buf: [64]u8 = undefined;
    const value_str = try getTrait(Show(T), T).show(value, &buf);
    std.debug.print("my {s}: {s}\n", .{ @typeName(T), value_str });
}

pub fn main() !void {
    const car: Car = .{
        .year = 1990,
        .make = "Toyota",
        .model = "Camry",
    };

    try printMyThing(Car, &car);
}

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
