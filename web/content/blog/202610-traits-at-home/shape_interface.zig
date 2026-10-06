const Shape = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    const VTable = struct {
        area: *const fn (*anyopaque) f32,
        perimiter: *const fn (*anyopaque) f32,
        containsPoint: *const fn (*anyopaque, f32, f32) bool,
    };
};
