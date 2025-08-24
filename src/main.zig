pub fn main() !void {
	try std.testing.expectEqual(
		cider.IpV4{ .decimal = std.math.maxInt(u32) },
		cider.IpV4.from(.{ 255, 255, 255, 255 })
	);
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const cider = @import("cider_lib");
