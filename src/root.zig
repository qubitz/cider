const std = @import("std");
const add = std.math.add;
const mul = std.math.mul;

pub const Cidr = struct {
    ip: IpV4,
    suffix: u6,

    pub fn from(str: []const u8) !Cidr {
        var octets: [4]u8 = undefined;
        var suffix: u6 = undefined;
        const State = union(enum) { octet: u3, dot: u3, slash, suffix };
        var curr = State{ .octet = 0 };

        var strIdx: usize = 0;
        while (strIdx < str.len) : (strIdx +=1) {
            switch (curr) {
                .octet => |x| {
                    octets[x], const skip = try stringToOctet(str[strIdx..]);
                    strIdx +=skip;
                    curr = if (x + 1 < octets.len) .{ .dot = x } else .slash;
                },
                .dot => |x| {
                    if (str[strIdx] == '.') {
                        curr = .{ .octet = x + 1 };
                    } else {
                        return error.InvalidDot;
                    }
                },
                .slash => {

                    if (str[strIdx] == '/') {
                        curr = .suffix;
                    } else {
                        return error.InvalidSlash;
                    }
                },
                .suffix => {
                    suffix = std.fmt.parseInt(u6, str[strIdx..], 10) catch {
                        return error.InvalidSuffix;
                    };
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
        var idx: u8 = 0;
        while (idx < @min(3, str.len)) : (idx += 1) {
            if (std.fmt.charToDigit(str[idx], 10)) |digit| {
                total = mul(u8, total, 10) catch { return error.OctetTooLarge; };
                total = add(u8, total, digit) catch { return error.OctetTooLarge; };
            } else |_| {
                if (idx == 0) return error.InvalidOctet;
                break;
            }
        }

        return .{ total, idx - 1 };
    }

    // comptime from string
};

pub const IpV4 = @Vector(4, u8);

test "cidr from string" {
    try std.testing.expectEqual(Cidr{
        .ip = .{ 1, 255, 2, 255 },
        .suffix = 8,
    }, try Cidr.from("1.255.2.255/8"));
}

test "creates octet from string" {
    try std.testing.expectEqual(.{@as(u8,123), 2}, Cidr.stringToOctet("123"));
    try std.testing.expectEqual(.{@as(u8,5), 0},  Cidr.stringToOctet("5"));
    try std.testing.expectEqual(.{@as(u8,27), 1}, Cidr.stringToOctet("27"));
    try std.testing.expectEqual(.{@as(u8,255), 2},  Cidr.stringToOctet("255"));

}
