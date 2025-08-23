pub fn main() !void {
    _ = try cider.Cidr.from("1.255.2.255/8");
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const cider = @import("cider_lib");
