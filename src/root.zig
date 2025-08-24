const std = @import("std");
const math = std.math

// TODO: use packed struct of 4 u8s. intCast as needed
pub const IpV4 = struct {
    const num_octets: u3 = 4;
    decimal: u32,

    pub fn from(octets: [num_octets]u8) IpV4 {
        var decimal: u32 = octets[0];
        decimal <<= @bitSizeOf(u8);
        decimal |=  octets[1];
        decimal <<= @bitSizeOf(u8);
        decimal |=  octets[2];
        decimal <<= @bitSizeOf(u8);
        decimal |= octets[3];

        return .{
            .decimal = decimal,
        };
    }

    test "converts octets to decimal" {
        try std.testing.expectEqual(
            IpV4{ .decimal = 0x01_02_03_04 },
            from(.{ 1, 2, 3, 4 })
        );
        try std.testing.expectEqual(
            IpV4{ .decimal = math.maxInt(u32) },
            from(.{ 255, 255, 255, 255 })
        );
    }
};

pub const Cidr = struct {
    ip: IpV4,
    suffix: u6,

    pub fn netAddress(self: *const Cidr) IpV4 {
        return .{
            .decimal = self.ip.decimal & ~math.shr(math.maxInt(u32), self.suffix),
        };
    }

    test "computes network address" {
        try std.testing.expectEqual(
            (strToIpV4("1.0.0.0") catch unreachable).@"0",
            (strToCidr("1.255.2.255/8") catch unreachable).netAddress(),
        );
    }
};

pub fn strToIpV4(str: []const u8) !struct { IpV4, u5 } {
    var octets: [IpV4.num_octets]u8 = undefined;
    const State = union(enum) { octet: u3, dot: u3 };
    var curr = State{ .octet = 0 };

    var strIdx: u5 = 0;
    while (strIdx < str.len) {
        switch (curr) {
            .octet => |x| {
                octets[x], const skip = try strToOctet(str[strIdx..]);
                strIdx += skip;
                curr = if (x + 1 < IpV4.num_octets) .{ .dot = x } else {
                    break;
                };
            },
            .dot => |x| {
                if (str[strIdx] == '.') {
                    curr = .{ .octet = x + 1 };
                    strIdx += 1;
                } else {
                    return error.InvalidDot;
                }
            },
        }
    }

    return .{
        IpV4.from(octets),
        strIdx,
    };
}

// comptime from string

pub fn strToCidr(str: []const u8) !Cidr {
    var ip: IpV4 = undefined;
    var suffix: u6 = undefined;
    const State = enum { ip, slash, suffix };
    var curr = State.ip;

    var strIdx: usize = 0;
    strLoop: while (strIdx < str.len) {
        switch (curr) {
            .ip => {
                ip, const skip = try strToIpV4(str[strIdx..]);
                strIdx += skip;
                curr = .slash;
            },
            .slash => {
                if (str[strIdx] == '/') {
                    curr = .suffix;
                    strIdx += 1;
                } else {
                    return error.InvalidSlash;
                }
            },
            .suffix => {
                suffix = std.fmt.parseInt(u6, str[strIdx..], 10) catch {
                    return error.InvalidSuffix;
                };
                break :strLoop;
            },
        }
    }

    return Cidr{
        .ip = ip,
        .suffix = suffix,
    };
}

const num_octet_digits = 3;
const add = std.math.add;
const mul = std.math.mul;

fn strToOctet(str: []const u8) !struct { u8, u3 } {
    var total: u8 = 0;
    var idx: u3 = 0;
    while (idx < @min(num_octet_digits, str.len)) : (idx += 1) {
        if (std.fmt.charToDigit(str[idx], 10)) |digit| {
            total = mul(u8, total, 10) catch {
                return error.OctetTooLarge;
            };
            total = add(u8, total, digit) catch {
                return error.OctetTooLarge;
            };
        } else |_| {
            if (idx == 0) return error.InvalidOctet;
            break;
        }
    }

    return .{ total, idx };
}

test "cidr from string" {
    try std.testing.expectEqual(Cidr{
        .ip = IpV4.from(.{ 1, 255, 2, 255 }),
        .suffix = 8,
    }, try strToCidr("1.255.2.255/8"));
}

test "creates octet from string" {
    try std.testing.expectEqual(.{ @as(u8, 123), 3 }, strToOctet("123"));
    try std.testing.expectEqual(.{ @as(u8, 5), 1 }, strToOctet("5"));
    try std.testing.expectEqual(.{ @as(u8, 27), 2 }, strToOctet("27"));
    try std.testing.expectEqual(.{ @as(u8, 255), 3 }, strToOctet("255"));
    try std.testing.expectEqual(error.OctetTooLarge, strToOctet("256"));
    try std.testing.expectEqual(error.InvalidOctet, strToOctet("abc"));
}

test "creates ipv4 from string" {
    try std.testing.expectEqual(.{ IpV4.from(.{ 1, 2, 3, 4 }), @as(u5, 7) }, strToIpV4("1.2.3.4"));
    try std.testing.expectEqual(.{ IpV4.from(.{ 1, 12, 123, 1 }), @as(u5, 10) }, strToIpV4("1.12.123.1"));
    try std.testing.expectEqual(error.InvalidDot, strToIpV4("1:2.3.4"));
}
