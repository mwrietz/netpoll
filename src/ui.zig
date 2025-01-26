const std = @import("std");
const uh = @import("ui-helpers.zig");
const ansi = @import("third-party/ansi.zig");

// const print = zth.print;
// const printColor = uh.printColor;
// const printInverseColor = uh.printInverseColor;

pub const MenuItem = struct {
    key: []const u8,
    action: []const u8,
};

pub fn horizLine() !void {
    const tsize = uh.TermSize.init(std.io.getStdOut());
    for (0..tsize.getWidth()) |_| {
        uh.printColor("─", .{}, "blue");
    }
}

pub fn headerUpdateMsg(msg: []const u8, version: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try ansi.Cursor.to(stdout, 0, 0);
    uh.printColor(" status:  ", .{}, "gray");
    uh.print("{s}", .{msg});

    // fill balance of msg window with spaces
    const num_spaces = try headerGetMsgWindowWidth(version) - msg.len - 10;
    for (0..num_spaces) |_| {
        uh.print(" ", .{});
    }
}

pub fn headerGetMsgWindowWidth(version: []const u8) !u32 {
    const tsize = uh.TermSize.init(std.io.getStdOut());

    const prog_name = try uh.getProgramName();
    const vlen: u32 = @intCast(version.len);
    const nlen: u32 = @intCast(prog_name.len);
    var msg_window_width: u32 = 0;
    if (tsize.getWidth() > (nlen + vlen + 1)) {
        msg_window_width = tsize.getWidth() - nlen - vlen - 3;
    }
    return msg_window_width;
}

pub fn header(version: []const u8) !void {
    const stdout = std.io.getStdOut().writer();

    // print version
    const xpos = try headerGetMsgWindowWidth(version) + 1;
    try ansi.Cursor.to(stdout, xpos, 0);
    uh.printColor("{s} {s}", .{ try uh.getProgramName(), version }, "orange");

    // print horizontal line
    try ansi.Cursor.to(stdout, 0, 1);
    try horizLine();
}

pub fn horizMenu(menu: std.ArrayList(MenuItem)) !void {
    const stdout = std.io.getStdOut().writer();

    const tsize = uh.TermSize.init(std.io.getStdOut());
    try ansi.Cursor.to(stdout, 0, tsize.getHeight() - 1);

    uh.printInverseColor(" {s} ", .{try uh.getProgramName()}, "orange");

    for (menu.items) |item| {
        uh.printColor("  {s}:", .{item.key}, "orange");
        uh.printColor("{s}", .{item.action}, "blue");
    }
}
