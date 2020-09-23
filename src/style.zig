// SPDX-License-Identifier: 0BSD
const std = @import("std");
const parseUnsigned = std.fmt.parseUnsigned;

/// Represents text and background color defined in one of the
/// several color palletes supported by terminal emulators.
pub const Color = union(enum) {
    /// Default foreground / background color. Note that many terminal
    /// emulators allow this color to be defined separately from the 16
    /// basic colors.
    default: void,

    /// 4-bit color. 0-7 are "normal" colors, while 8-15 are "bright" colors.
    basic: u4,

    /// 8-bit color, supporting 256 unique colors. Colors 0-15 correspond
    /// to the same values as basic colors 0-15, while 16-255 are unique.
    extended: u8,

    /// 24-bit "true color." Supports the full range of colors used in modern
    /// graphical applications, but is not supported in older environments.
    /// Termcon will fall back to 8-bit color where 24-bit color is unsupported.
    rgb: struct {
        red: u8,
        green: u8,
        blue: u8,
    },

    /// Parse a string of 6 hex digits into a 24-bit color structure. This
    /// function does not handle a leading # character. If you need to handle
    /// strings with a leading #, simply slice them accordingly. Also, shorthand
    /// notation is not permitted: this function only handles 6-digit hex strings
    /// as they are the most ubiquitous way of specifying color.
    pub fn parseHex(str: []const u8) error{InvalidHexString}!Color {
        if (str.len != 6) return error.InvalidHexString;
        return Color{
            .rgb = .{
                .red = parseUnsigned(u8, str[0..2], 16) catch return error.InvalidHexString,
                .green = parseUnsigned(u8, str[2..4], 16) catch return error.InvalidHexString,
                .blue = parseUnsigned(u8, str[4..6], 16) catch return error.InvalidHexString,
            },
        };
    }
};

/// Various text attributes that are supported by a few terminal emulators.
/// Use at your own risk, and prefer extended or RGB color as some attributes
/// may change the displayed color for basic 4-bit color.
pub const Attributes = struct {
    dim: bool = false,
    bold: bool = false,
    italic: bool = false,
    reverse: bool = false,
    underline: bool = false,
    blinking: bool = false,
};

test "termcon.style.parseHex" {
    const expectEqual = std.testing.expectEqual;
    const expectError = std.testing.expectError;
    const color = Color{
        .rgb = .{
            .red = 240,
            .green = 128,
            .blue = 255,
        },
    };
    expectEqual(color, try Color.parseHex("f080ff"));
    expectEqual(color, comptime (Color.parseHex("f080ff") catch unreachable));
    expectError(error.InvalidHexString, Color.parseHex("455"));
    expectError(error.InvalidHexString, Color.parseHex("z7y8g9"));
    expectError(error.InvalidHexString, Color.parseHex("+000000"));
    expectError(error.InvalidHexString, Color.parseHex("-000000"));
}
