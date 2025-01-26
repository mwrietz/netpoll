const std = @import("std");
const zth = @import("modules/zig-tui-helpers.zig");
const ansi = @import("modules/ansi.zig");
const terminal = @import("modules/ztui-tabby/terminal.zig");
const event_reader = @import("modules/ztui-tabby/events/event_reader.zig");
const np = @import("modules/network_poll.zig");
const keycodes = event_reader.keycodes;

const print = zth.print;
const printColor = zth.printColor;
const printInverseColor = zth.printInverseColor;
const clear = zth.clear;

const version = "v0.1.0";

const Allocator = std.mem.Allocator;

const MenuItem = struct {
    key: []const u8,
    action: []const u8,
};

pub fn main() !void {

    // setup menu items
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const status = gpa.deinit();
        if (status == .leak) @panic("Memory Leak Occured");
    }

    var menu = std.ArrayList(MenuItem).init(allocator);
    defer menu.deinit();

    try menu.append(.{ .key = "p", .action = "Poll_Network" });
    try menu.append(.{ .key = "q", .action = "Quit" });

    // clear screen, display header, display menu
    try clear();
    try header();
    try headerUpdateMsg("Waiting for input...");
    try horizMenu(menu);

    // hide cursor and enable raw mode
    try ansi.Cursor.hide(std.io.getStdOut().writer());
    try terminal.enableRawMode();
    defer terminal.disableRawMode() catch {};

    // wait for and process user input
    while (true) {
        const res = try event_reader.read(allocator);
        defer res.deinit();
        for (res.items) |event| {
            switch (event.code) {
                .Char => |char| {
                    if (char == 'p') {
                        try headerUpdateMsg("Polling network...");
                        try selection_p();
                        try headerUpdateMsg("Polling complete.");
                    }
                    if (char == 'q') {
                        try selection_q();
                        return;
                    }
                },
                else => {},
            }
        }
    }
}

pub fn selection_p() !void {
    const stdout = std.io.getStdOut().writer();

    // clear the main window
    const tsize = zth.TermSize.init(std.io.getStdOut());
    const top_line = 2;
    const bottom_line = tsize.getHeight() - 3;
    const num_lines = bottom_line - top_line;
    try ansi.Cursor.to(stdout, 0, top_line);
    for (0..num_lines) |_| {
        try ansi.Erase.line(stdout);
        try ansi.Cursor.move(stdout, 0, 1);
    }

    try ansi.Cursor.to(stdout, 0, 4);
    try np.network_poll();
}

pub fn selection_q() !void {
    try clear();
    try ansi.Cursor.show(std.io.getStdOut().writer());
}

pub fn horizLine() !void {
    const tsize = zth.TermSize.init(std.io.getStdOut());
    for (0..tsize.getWidth()) |_| {
        printColor("─", .{}, "blue");
    }
}

pub fn headerUpdateMsg(msg: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try ansi.Cursor.to(stdout, 0, 0);
    zth.printColor(" status:  ", .{}, "gray");
    zth.print("{s}", .{msg});
    // fill balance of msg window with spaces
    const num_spaces = try headerGetMsgWindowWidth() - msg.len - 10;
    for (0..num_spaces) |_| {
        zth.print(" ", .{});
    }
}

pub fn headerGetMsgWindowWidth() !u32 {
    // get terminal size and position cursor
    const tsize = zth.TermSize.init(std.io.getStdOut());

    const allocator = std.heap.page_allocator;
    const prog_name = try zth.getProgramName(allocator);
    const vlen: u32 = @intCast(version.len);
    const nlen: u32 = @intCast(prog_name.len);
    var msg_window_width: u32 = 0;
    if (tsize.getWidth() > (nlen + vlen + 1)) {
        msg_window_width = tsize.getWidth() - nlen - vlen - 3;
    }
    return msg_window_width;
}

pub fn header() !void {
    const allocator = std.heap.page_allocator;
    const prog_name = try zth.getProgramName(allocator);

    const stdout = std.io.getStdOut().writer();

    // print version
    const xpos = try headerGetMsgWindowWidth() + 1;
    try ansi.Cursor.to(stdout, xpos, 0);
    printColor("{s} {s}", .{ prog_name, version }, "orange");

    // print horizontal line
    try ansi.Cursor.to(stdout, 0, 1);
    try horizLine();
}

pub fn horizMenu(menu: std.ArrayList(MenuItem)) !void {
    const stdout = std.io.getStdOut().writer();

    const tsize = zth.TermSize.init(std.io.getStdOut());
    try ansi.Cursor.to(stdout, 0, tsize.getHeight() - 1);
    try printTitleBlock();

    for (menu.items) |item| {
        printColor("  {s}:", .{item.key}, "orange");
        printColor("{s}", .{item.action}, "blue");
    }
}

pub fn printTitleBlock() !void {
    const allocator = std.heap.page_allocator;
    const prog_name = try zth.getProgramName(allocator);

    printInverseColor(" {s} ", .{prog_name}, "orange");
}
