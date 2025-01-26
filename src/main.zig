const std = @import("std");

const np = @import("network_poll.zig");
const ui = @import("ui.zig");
const uh = @import("ui-helpers.zig");

const ansi = @import("third-party/ansi.zig");
const terminal = @import("third-party/ztui-tabby/terminal.zig");
const event_reader = @import("third-party/ztui-tabby/events/event_reader.zig");
const keycodes = event_reader.keycodes;

const print = uh.print;
const printColor = uh.printColor;
const printInverseColor = uh.printInverseColor;

const version = "v0.1.3";

pub fn main() !void {

    // setup menu items
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const status = gpa.deinit();
        if (status == .leak) @panic("Memory Leak Occured");
    }

    var menu = std.ArrayList(ui.MenuItem).init(allocator);
    defer menu.deinit();

    try menu.append(.{ .key = "p", .action = "Poll_Network" });
    try menu.append(.{ .key = "q", .action = "Quit" });

    // clear screen, display header, display menu
    try ansi.Clear.screen(std.io.getStdOut());
    try ui.header(version);
    try ui.headerUpdateMsg("Waiting for input...", version);
    try ui.horizMenu(menu);

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
                        try ui.headerUpdateMsg("Polling network...", version);
                        try selection_p();
                        try ui.headerUpdateMsg("Polling complete.", version);
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
    const tsize = uh.TermSize.init(std.io.getStdOut());
    const top_line = 2;
    const bottom_line = tsize.getHeight() - 3;
    const num_lines = bottom_line - top_line;
    try ansi.Cursor.to(stdout, 0, top_line);
    for (0..num_lines) |_| {
        try ansi.Erase.line(stdout);
        try ansi.Cursor.move(stdout, 0, 1);
    }

    // move to top of main window
    try ansi.Cursor.to(stdout, 0, 4);
    try np.network_poll();
}

pub fn selection_q() !void {
    try ansi.Clear.screen(std.io.getStdOut());
    try ansi.Cursor.show(std.io.getStdOut().writer());
}
