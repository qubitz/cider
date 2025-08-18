const std = @import("std");

pub const Cidr = struct {
    ip: IpV4,
    suffix: u6,

    pub fn from(str: []const u8) !Cidr {
        var octets: [4]u8 = undefined;
        var suffix: u6 = undefined;
        const State = union(enum) { octet: u2, dot: u2, slash, suffix };
        var curr = State{ .octet = 0 };

        var strIdx: usize = 0;
        while (strIdx < str.len) {
            switch (curr) {
                .octet => |x| {
                    octets[x], strIdx = try stringToOctet(str[strIdx..]);
                    curr = if (x + 1 < octets.len) .{ .dot = x } else .slash;
                },
                .dot => |x| {
                    if (str[strIdx] == '.') {
                        curr = State{ .octet = x + 1 };
                        strIdx += 1;
                    } else {
                        return error.InvalidCharacter;
                    }
                },
                .slash => {
                    if (str[strIdx] == '/') {
                        curr = .suffix;
                        strIdx += 1;
                    } else {
                        return error.InvalidCharacter;
                    }
                },
                .suffix => {
                    suffix = try std.fmt.parseInt(u6, str[strIdx..], 10);
                },
            }
        }

        return Cidr{
            .ip = octets,
            .suffix = suffix,
        };
    }

    fn stringToOctet(str: []const u8) !struct { u8, usize } {
        var total: u8 = 0;
        var mult: u8 = 1;
        var idx: u8 = 0;
        while (idx < 3) : (idx += 1) {
            if (std.fmt.charToDigit(str[idx], 10)) |digit| {
                total += digit * mult;
            } else |_| {
                if (idx == 0) return error.InvalidCharacter;
                break;
            }
            mult *= 10;
        }

        return .{ total, idx };
    }

    // comptime from string
};

pub const IpV4 = @Vector(4, u8);

test "cidr from string" {
    try std.testing.expectEqual(Cidr{
        .ip = .{ 255, 255, 255, 255 },
        .suffix = 8,
    }, Cidr.from("1.255.2.255/8"));
}
