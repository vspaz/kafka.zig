const std = @import("std");

pub fn main() !void {}

test {
    std.testing.refAllDecls(@This());
}
