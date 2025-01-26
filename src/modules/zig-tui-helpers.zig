// zig-tui-helpers.zig

const std = @import("std");
const ansi = @import("ansi.zig").ansi;
const datetime = @import("datetime.zig");
const zc = @import("zig-colors.zig");

const builtin = @import("builtin");
const io = std.io;
const os = std.os;

const bufPrint = std.fmt.bufPrint;

pub fn clear() !void {
    const stdout = std.io.getStdOut().writer();
    try ansi.clear.screen(stdout);
}

pub fn getColor(color: []const u8) zc.Color {
    if (std.mem.eql(u8, "black", color)) return zc.Color.black;
    if (std.mem.eql(u8, "red", color)) return zc.Color.red;
    if (std.mem.eql(u8, "green", color)) return zc.Color.green;
    if (std.mem.eql(u8, "yellow", color)) return zc.Color.yellow;
    if (std.mem.eql(u8, "blue", color)) return zc.Color.blue;
    if (std.mem.eql(u8, "magenta", color)) return zc.Color.magenta;
    if (std.mem.eql(u8, "cyan", color)) return zc.Color.cyan;
    if (std.mem.eql(u8, "white", color)) return zc.Color.white;
    if (std.mem.eql(u8, "orange", color)) return zc.Color.orange;
    return zc.Color.reset;
}

pub fn getInt(prompt: []const u8) !i32 {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    var buf: [100]u8 = undefined;

    while (true) {
        print("{s}", .{prompt});

        if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |user_input| {
            const trimmed = std.mem.trim(u8, user_input, " \t\r\n");
            if (std.fmt.parseInt(i32, trimmed, 10)) |number| {
                return number;
            } else |_| {
                try stdout.print("Please enter a valid integer.\n", .{});
                continue;
            }
        } else {
            return error.InvalidInput;
        }
    }
}

pub fn getFloat(prompt: []const u8) !f64 {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    var buf: [100]u8 = undefined;

    while (true) {
        print("{s}", .{prompt});

        if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |user_input| {
            const trimmed = std.mem.trim(u8, user_input, " \t\r\n");
            if (std.fmt.parseFloat(f64, trimmed)) |number| {
                return number;
            } else |_| {
                try stdout.print("Please enter a valid float.\n", .{});
                continue;
            }
        } else {
            return error.InvalidInput;
        }
    }
}

pub fn getProgramName() ![]const u8 {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    return std.fs.path.basename(args[0]);
}

pub fn print(comptime fmt: []const u8, args: anytype) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print(fmt, args) catch |err| {
        std.debug.print("Error while printing: {}\n", .{err});
        return;
    };
}

pub fn printColor(comptime fmt: []const u8, args: anytype, color: []const u8) void {
    const stdout = std.io.getStdOut().writer();

    stdout.print("{s}", .{getColor(color).foreground()}) catch |err| {
        std.debug.print("Error while printing: {}\n", .{err});
        return;
    };
    stdout.print(fmt, args) catch |err| {
        std.debug.print("Error while printing: {}\n", .{err});
        return;
    };
    stdout.print("{s}", .{getColor("reset").foreground()}) catch |err| {
        std.debug.print("Error while printing: {}\n", .{err});
        return;
    };
}

pub fn printInverseColor(comptime fmt: []const u8, args: anytype, color: []const u8) void {
    const stdout = std.io.getStdOut().writer();

    stdout.print("{s}{s}", .{ getColor(color).background(), zc.Color.black.foreground() }) catch |err| {
        std.debug.print("Error while printing: {}\n", .{err});
        return;
    };
    stdout.print(fmt, args) catch |err| {
        std.debug.print("Error while printing: {}\n", .{err});
        return;
    };
    stdout.print("{s}{s}", .{ getColor("reset").background(), zc.Color.reset.foreground() }) catch |err| {
        std.debug.print("Error while printing: {}\n", .{err});
        return;
    };
}

pub const TermSize = struct {
    width: u16,
    height: u16,

    pub fn init(file: std.fs.File) TermSize {
        var buf: std.posix.system.winsize = undefined;
        _ = std.posix.system.ioctl(file.handle, std.posix.T.IOCGWINSZ, @intFromPtr(&buf));
        return TermSize{
            .width = buf.ws_col,
            .height = buf.ws_row,
        };
    }

    pub fn getWidth(self: TermSize) u16 {
        return self.width;
    }

    pub fn getHeight(self: TermSize) u16 {
        return self.height;
    }
};

pub fn timestamp() ![]u8 {
    // get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa.deinit();
        if (check == .leak) @panic("Memory leak!");
    }
    const allocator = gpa.allocator();

    // get datetime stamp
    const dt = datetime.Datetime.now();
    const dt_str = try dt.formatISO8601(allocator, false);
    defer allocator.free(dt_str);

    var dt_str_utc: [29]u8 = undefined;
    @memcpy(dt_str_utc[0..dt_str.len], dt_str);
    @memcpy(dt_str_utc[dt_str.len..], "_UTC");

    const dt_str_copy = try std.heap.page_allocator.dupe(u8, &dt_str_utc);
    return dt_str_copy;
}
