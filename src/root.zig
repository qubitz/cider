const std = @import("std");

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
                    std.debug.print("octect {d} = {d}\n", .{x, octets[x]});
                    std.debug.print("strIdx = {d}\n", .{strIdx});
                    curr = if (x + 1 < octets.len) .{ .dot = x } else .slash;
                },
                .dot => |x| {
                    if (str[strIdx] == '.') {
                        std.debug.print("dot {d}\n", .{x});
                        curr = .{ .octet = x + 1 };
                    } else {
                        return error.InvalidCharacter;
                    }
                },
                .slash => {

                    if (str[strIdx] == '/') {
                        std.debug.print("slash\n", .{});
                        curr = .suffix;
                    } else {
                        return error.InvalidCharacter;
                    }
                },
                .suffix => {
                    suffix = try std.fmt.parseInt(u6, str[strIdx..], 10);
                    std.debug.print("suffix\n", .{});
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
        while (idx < 3) : (idx += 1) {
            //        out of bounds   vvvvvv
            if (std.fmt.charToDigit(str[idx], 10)) |digit| {
                std.debug.print("digit = {d}\n", .{digit});
                total = total * 10 + digit;
                std.debug.print("total = {d}, idx = {d}\n", .{total, idx});
            } else |_| {
                if (idx == 0) return error.InvalidCharacter;
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
