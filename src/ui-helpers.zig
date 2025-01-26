const std = @import("std");
const uc = @import("ui-color.zig");

const ansi = @import("third-party/ansi.zig").ansi;
const datetime = @import("third-party/datetime.zig");

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

    stdout.print("{s}", .{uc.getColor(color).foreground()}) catch |err| {
        std.debug.print("Error while printing: {}\n", .{err});
        return;
    };
    stdout.print(fmt, args) catch |err| {
        std.debug.print("Error while printing: {}\n", .{err});
        return;
    };
    stdout.print("{s}", .{uc.getColor("reset").foreground()}) catch |err| {
        std.debug.print("Error while printing: {}\n", .{err});
        return;
    };
}

pub fn printInverseColor(comptime fmt: []const u8, args: anytype, color: []const u8) void {
    const stdout = std.io.getStdOut().writer();

    stdout.print("{s}{s}", .{ uc.getColor(color).background(), uc.Color.black.foreground() }) catch |err| {
        std.debug.print("Error while printing: {}\n", .{err});
        return;
    };
    stdout.print(fmt, args) catch |err| {
        std.debug.print("Error while printing: {}\n", .{err});
        return;
    };
    stdout.print("{s}{s}", .{ uc.getColor("reset").background(), uc.Color.reset.foreground() }) catch |err| {
        std.debug.print("Error while printing: {}\n", .{err});
        return;
    };
}

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
