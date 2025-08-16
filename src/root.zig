const std = @import("std");
const testing = std.testing;

pub export fn new(octets: [4]u8) Cidr {
    return .{
        .ipAddress = .{
            .octets = octets,
        },
    };
}

const Cidr = struct {
    ipAddress: IpAddress,
    maskLength: u8,
};

const IpAddress = struct {
    octets: u8[4],
};

