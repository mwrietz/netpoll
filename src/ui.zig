const std = @import("std");
const zth = @import("zig-tui-helpers.zig");
const ansi = @import("third-party/ansi.zig");
// const terminal = @import("modules/ztui-tabby/terminal.zig");
// const event_reader = @import("modules/ztui-tabby/events/event_reader.zig");
// const np = @import("modules/network_poll.zig");
// const keycodes = event_reader.keycodes;
//
// const print = zth.print;
const printColor = zth.printColor;
const printInverseColor = zth.printInverseColor;
//
// const version = "v0.1.0";
//
// const Allocator = std.mem.Allocator;
//
pub const MenuItem = struct {
    key: []const u8,
    action: []const u8,
};

pub fn horizLine() !void {
    const tsize = zth.TermSize.init(std.io.getStdOut());
    for (0..tsize.getWidth()) |_| {
        printColor("─", .{}, "blue");
    }
}

pub fn headerUpdateMsg(msg: []const u8, version: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try ansi.Cursor.to(stdout, 0, 0);
    zth.printColor(" status:  ", .{}, "gray");
    zth.print("{s}", .{msg});
    // fill balance of msg window with spaces
    const num_spaces = try headerGetMsgWindowWidth(version) - msg.len - 10;
    for (0..num_spaces) |_| {
        zth.print(" ", .{});
    }
}

pub fn headerGetMsgWindowWidth(version: []const u8) !u32 {
    // get terminal size and position cursor
    const tsize = zth.TermSize.init(std.io.getStdOut());

    //const allocator = std.heap.page_allocator;
    const prog_name = try zth.getProgramName();
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
    printColor("{s} {s}", .{ try zth.getProgramName(), version }, "orange");

    // print horizontal line
    try ansi.Cursor.to(stdout, 0, 1);
    try horizLine();
}

pub fn horizMenu(menu: std.ArrayList(MenuItem)) !void {
    const stdout = std.io.getStdOut().writer();

    const tsize = zth.TermSize.init(std.io.getStdOut());
    try ansi.Cursor.to(stdout, 0, tsize.getHeight() - 1);

    printInverseColor(" {s} ", .{try zth.getProgramName()}, "orange");

    for (menu.items) |item| {
        printColor("  {s}:", .{item.key}, "orange");
        printColor("{s}", .{item.action}, "blue");
    }
}
