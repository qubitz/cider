pub fn main() !void {
    _= try cider.Cidr.from("123.2.24.255/22");
}


const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const cider = @import("cider_lib");
