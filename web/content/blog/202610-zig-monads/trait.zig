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
