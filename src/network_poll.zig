const std = @import("std");
const mn = @import("mynet.zig");

const uh = @import("ui-helpers.zig");
const ansi = @import("third-party/ansi.zig");

const RunError = error{
    Failed,
};

pub fn network_poll() !void {
    const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var ip_list = std.ArrayList([]const u8).init(alloc);
    defer ip_list.deinit();

    var hostname_map = std.StringHashMap([]const u8).init(alloc);
    defer hostname_map.deinit();

    try network_poll_all(&ip_list, &hostname_map);
    try network_poll_up(&ip_list, &hostname_map);

    const deduped_ip_list = try dedupAndSortStrings(alloc, ip_list);
    errdefer {
        for (deduped_ip_list.items) |item| {
            alloc.free(item);
        }
        deduped_ip_list.deinit();
    }

    try ansi.Cursor.to(stdout, 0, 2);
    uh.printColor("          IP Address       Hostname\n", .{}, "blue");
    try ansi.Cursor.to(stdout, 0, null);
    var count: u32 = 0;
    for (deduped_ip_list.items) |ip| {
        count += 1;
        const hostname = hostname_map.get(ip);
        uh.printColor("    {:3}:  ", .{count}, "blue");
        uh.print("{s:<16} {?s}\n", .{ ip, hostname });
        try ansi.Cursor.to(stdout, 0, null);
    }
}

pub fn network_poll_all(ip_list: *std.ArrayList([]const u8), hostname_map: *std.StringHashMap([]const u8)) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    const my_net_ip_range = try mn.getMyNetIPv4();

    const out = try callCommand(alloc, &[_][]const u8{ "nmap", "-sn", "-Pn", my_net_ip_range });
    defer out.deinit();

    var lines = std.mem.split(u8, out.items, "\n");

    // + push all ip addresses from "all" list (ip's with hostnames)
    while (lines.next()) |line| {
        if (strBeginsWith(line, "Nmap scan")) {
            var word_list = try sentenceToWords(line);
            defer word_list.deinit();

            // append devices that include a hostname
            if (word_list.items.len == 6) {
                const ip = std.mem.trim(u8, word_list.items[5], "()");
                try ip_list.append(try alloc.dupe(u8, ip));

                if (hostname_map.get(ip) == null) {
                    try hostname_map.put(try alloc.dupe(u8, ip), try alloc.dupe(u8, word_list.items[4]));
                }
            }
        }
    }
}

pub fn network_poll_up(ip_list: *std.ArrayList([]const u8), hostname_map: *std.StringHashMap([]const u8)) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    const my_net_ip_range = try mn.getMyNetIPv4();

    const out = try callCommand(alloc, &[_][]const u8{ "nmap", "-sn", my_net_ip_range });
    defer out.deinit();

    var lines = std.mem.split(u8, out.items, "\n");

    while (lines.next()) |line| {
        if (strBeginsWith(line, "Nmap scan")) {
            var word_list = try sentenceToWords(line);
            defer word_list.deinit();

            if (word_list.items.len == 5) {
                const ip = word_list.items[4];
                try ip_list.append(try alloc.dupe(u8, ip));
            }

            if (word_list.items.len == 6) {
                const ip = std.mem.trim(u8, word_list.items[5], "()");
                try ip_list.append(try alloc.dupe(u8, ip));
                if (hostname_map.get(ip) == null) {
                    try hostname_map.put(try alloc.dupe(u8, ip), word_list.items[4]);
                }
            }
        }
    }
}

pub fn sentenceToWords(sentence: []const u8) !std.ArrayList([]const u8) {
    const allocator = std.heap.page_allocator;

    var words = std.ArrayList([]const u8).init(allocator);
    errdefer words.deinit();

    // Trim leading and trailing whitespace
    const trimmed = std.mem.trim(u8, sentence, " \t\n\r");

    // Split the sentence by whitespace
    var iterator = std.mem.splitScalar(u8, trimmed, ' ');

    while (iterator.next()) |word| {
        // Skip empty words (multiple consecutive spaces)
        if (word.len > 0) {
            try words.append(word);
        }
    }

    return words;
}

pub fn strBeginsWith(s1: []const u8, s2: []const u8) bool {
    if (s1.len >= s2.len) {
        for (0..s2.len) |i| {
            if (s1[i] != s2[i]) {
                return false;
            }
        }
        return true;
    } else {
        return false;
    }
}

pub fn callCommand(alloc: std.mem.Allocator, command: []const []const u8) !std.ArrayList(u8) {
    var caller = std.process.Child.init(command, alloc);
    caller.stdout_behavior = .Pipe;
    caller.stderr_behavior = .Pipe;

    var stdout = std.ArrayList(u8).init(alloc);
    var stderr = std.ArrayList(u8).init(alloc);
    errdefer stdout.deinit();
    defer stderr.deinit();

    try caller.spawn(); // Error points to here...
    try caller.collectOutput(&stdout, &stderr, 20480);

    const res = try caller.wait();

    if (res.Exited > 0) {
        std.debug.print("{s}\n", .{stderr.items});
        return RunError.Failed;
    } else {
        return stdout;
    }
}

pub fn dedupAndSortStrings(allocator: std.mem.Allocator, input_list: std.ArrayList([]const u8)) !std.ArrayList([]const u8) {

    // Sort the input list
    var sorted_list = try input_list.clone();
    defer sorted_list.deinit();

    // Sort the list
    std.mem.sort([]const u8, sorted_list.items, {}, stringLessThan);

    // Create a new list to store unique strings
    var unique_list = std.ArrayList([]const u8).init(allocator);
    errdefer unique_list.deinit();

    // Add unique strings
    for (sorted_list.items) |current_str| {
        if (unique_list.items.len == 0 or
            !std.mem.eql(u8, current_str, unique_list.items[unique_list.items.len - 1]))
        {
            try unique_list.append(try allocator.dupe(u8, current_str));
        }
    }

    return unique_list;
}

fn stringLessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs) == .lt;
}
