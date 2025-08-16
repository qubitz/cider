const std = @import("std");
const testing = std.testing;



pub const Cidr = struct {
    ipAddress: IpV4,
    maskLength: u8,

    pub fn init(octets: @Vector(4, u8)) Cidr {
        return .{
            .ipAddress = .{
                .octets = octets,
            },
            .maskLength = 2,
        };
    }
};

pub const IpV4 = struct {
    octets: @Vector(4, u8),
};

