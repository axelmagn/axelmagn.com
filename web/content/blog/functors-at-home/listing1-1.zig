fn mapInts(values: []i32, output: []i32, function: *const fn (i32) i32) void {
    const n = @min(values.len, output.len);
    for (0..n) |i| {
        output[i] = function(values[i]);
    }
}

fn mul2(x: i32) i32 {
    return x * 2;
}

fn add3(x: i32) i32 {
    return x + 3;
}

export fn run(input: [*c]i32, output: [*c]i32, n: usize) void {
    mapInts(input[0..n], output[0..n], mul2);
    mapInts(output[0..n], output[0..n], add3);
}
