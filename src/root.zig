const std = @import("std");

pub const IpV4 = @Vector(4, u8);

pub const Cidr = struct {
    ip: IpV4,
    suffix: u6,
};

const numOctets: u3 = 4;

pub fn strToIpV4(str: []const u8) !struct { IpV4, u5 } {
    var octets: [numOctets]u8 = undefined;
    const State = union(enum) { octet: u3, dot: u3 };
    var curr = State{ .octet = 0 };

    var strIdx: u5 = 0;
    while (strIdx < str.len) {
        switch (curr) {
            .octet => |x| {
                octets[x], const skip = try strToOctet(str[strIdx..]);
                strIdx += skip;
                curr = if (x + 1 < numOctets) .{ .dot = x } else {
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
        octets,
        strIdx,
    };
}

// comptime from string

pub fn from(str: []const u8) !Cidr {
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

const numOctetDigits = 3;
const add = std.math.add;
const mul = std.math.mul;

fn strToOctet(str: []const u8) !struct { u8, u3 } {
    var total: u8 = 0;
    var idx: u3 = 0;
    while (idx < @min(numOctetDigits, str.len)) : (idx += 1) {
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
        .ip = .{ 1, 255, 2, 255 },
        .suffix = 8,
    }, try Cidr.from("1.255.2.255/8"));
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
    try std.testing.expectEqual(.{ .{ 1, 2, 3, 4 }, @as(u5, 7) }, strToIpV4("1.2.3.4"));
    try std.testing.expectEqual(.{ .{ 1, 12, 123, 1 }, @as(u5, 10) }, strToIpV4("1.12.123.1"));
    try std.testing.expectEqual(error.InvalidDot, strToIpV4("1:2.3.4"));
}
