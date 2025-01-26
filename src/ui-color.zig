const std = @import("std");

/// Color enum with ANSI escape sequence support
pub const Color = enum {
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    orange,
    gray,
    reset,

    /// Returns the ANSI escape sequence for foreground color
    pub fn foreground(self: Color) []const u8 {
        return switch (self) {
            .black => "\x1b[30m",
            .red => "\x1b[31m",
            .green => "\x1b[32m",
            .yellow => "\x1b[33m",
            .blue => "\x1b[34m",
            .magenta => "\x1b[35m",
            .cyan => "\x1b[36m",
            .white => "\x1b[37m",
            .orange => "\x1b[38;5;208m",
            .gray => "\x1b[38;5;245m",
            .reset => "\x1b[0m",
        };
    }

    /// Returns the ANSI escape sequence for background color
    pub fn background(self: Color) []const u8 {
        return switch (self) {
            .black => "\x1b[40m",
            .red => "\x1b[41m",
            .green => "\x1b[42m",
            .yellow => "\x1b[43m",
            .blue => "\x1b[44m",
            .magenta => "\x1b[45m",
            .cyan => "\x1b[46m",
            .white => "\x1b[47m",
            .orange => "\x1b[48;5;208m",
            .gray => "\x1b[38;5;245m",
            .reset => "\x1b[0m",
        };
    }
};

pub fn getColor(color: []const u8) Color {
    if (std.mem.eql(u8, "black", color)) return Color.black;
    if (std.mem.eql(u8, "red", color)) return Color.red;
    if (std.mem.eql(u8, "green", color)) return Color.green;
    if (std.mem.eql(u8, "yellow", color)) return Color.yellow;
    if (std.mem.eql(u8, "blue", color)) return Color.blue;
    if (std.mem.eql(u8, "magenta", color)) return Color.magenta;
    if (std.mem.eql(u8, "cyan", color)) return Color.cyan;
    if (std.mem.eql(u8, "white", color)) return Color.white;
    if (std.mem.eql(u8, "orange", color)) return Color.orange;
    return Color.reset;
}
