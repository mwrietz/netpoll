const std = @import("std");
const mn = @import("mynet.zig");
const zth = @import("zig-tui-helpers.zig");
const ansi = @import("ansi.zig");
const Child = std.process.Child;

const RunError = error{
    Failed,
};

pub fn network_poll() !void {
    const stdout = std.io.getStdOut().writer();
    try ansi.Cursor.to(stdout, 0, 2);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    // get my ip address and format with last char = '*'
    const my_net_ip_range = try mn.getMyNetIPv4();

    // todo
    // create ArrayList of ip addresses
    // push all ip addresses from "all" list (ip's with hostnames)
    // push all ip addresses from "up" list
    // sort and deduplicate arraylist
    // create hashmap with ip addresses as keys and hostnames as values
    // print arraylist of ip addresses and print hostnames when they exist in the hashmap

    // const out_up_only = try callCommand(alloc, &[_][]const u8{ "nmap", "-sn", "-Pn", my_net_ip_range });
    // defer out_up_only.deinit();
    const out_all = try callCommand(alloc, &[_][]const u8{ "nmap", "-sn", "-Pn", my_net_ip_range });
    defer out_all.deinit();

    // split output into lines iterator
    var lines_all = std.mem.split(u8, out_all.items, "\n");
    // var lines_up_only = std.mem.split(u8, out_up_only.items, "\n");

    var ip_list = std.ArrayList([]const u8).init(alloc);
    var hostname_map = std.StringHashMap([]const u8).init(alloc);

    var count: u32 = 0;
    while (lines_all.next()) |line| {
        if (strBeginsWith(line, "Nmap scan")) {

            // parse line
            const allocator = std.heap.page_allocator;
            var wordList = try sentenceToWords(allocator, line);
            defer wordList.deinit();

            // print devices that don't include a hostname
            // if (wordList.items.len == 5) {
            //     std.debug.print("{:2}: {s:<16}\n", .{ count, wordList.items[4] });
            // }

            // print devices that include a hostname
            if (wordList.items.len == 6) {

                // add ip address to list
                const ip = std.mem.trim(u8, wordList.items[5], "()");
                try ip_list.append(ip);

                // add ip and hostname to hashmap
                try hostname_map.put(ip, wordList.items[4]);

                // print ip address and hostname
                count += 1;
                zth.printColor("    {:3}:  ", .{count}, "gray");
                zth.print("{s:<16} {s}\n", .{ std.mem.trim(u8, wordList.items[5], "()"), wordList.items[4] });
                try ansi.Cursor.to(stdout, 0, null);
            }
        }
    }
    for (ip_list.items) |ip| {
        const hostname = hostname_map.get(ip);
        //zth.print("Type: {any}\n", .{@TypeOf(hostname)});
        zth.print("{s} {?s}\n", .{ ip, hostname });
        //zth.print("{s} {s}\n", .{ ip, hostname });
        try ansi.Cursor.to(stdout, 0, null);
    }
}

pub fn sentenceToWords(allocator: std.mem.Allocator, sentence: []const u8) !std.ArrayList([]const u8) {
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
    var caller = Child.init(command, alloc);
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

// pub fn dedupAndSortStrings(allocator: std.mem.Allocator, input_list: std.ArrayList([]const u8)) !std.ArrayList([]const u8) {
//     // Sort the input list
//     var sorted_list = try input_list.clone(allocator);
//     defer sorted_list.deinit();
//     std.sort.sort([]const u8, sorted_list.items, {}, comptime std.sort.asc([]const u8));
//
//     // Create a new list to store unique strings
//     var unique_list = std.ArrayList([]const u8).init(allocator);
//     errdefer unique_list.deinit();
//
//     // Add unique strings
//     for (sorted_list.items) |current_str| {
//         if (unique_list.items.len == 0 or
//             !std.mem.eql(u8, current_str, unique_list.items[unique_list.items.len - 1])) {
//             try unique_list.append(try allocator.dupe(u8, current_str));
//         }
//     }
//
//     return unique_list;
// }
//
// test "dedup and sort strings" {
//     var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
//     defer arena.deinit();
//     const allocator = arena.allocator();
//
//     var test_list = std.ArrayList([]const u8).init(allocator);
//     defer test_list.deinit();
//
//     try test_list.appendSlice(&[_][]const u8{"banana", "apple", "cherry", "banana", "apple"});
//
//     const result = try dedupAndSortStrings(allocator, test_list);
//     defer {
//         for (result.items) |item| {
//             allocator.free(item);
//         }
//         result.deinit();
//     }
//
//     const expected = &[_][]const u8{"apple", "banana", "cherry"};
//     try std.testing.expectEqual(expected.len, result.items.len);
//     for (expected, 0..) |exp, i| {
//         try std.testing.expectEqualStrings(exp, result.items[i]);
//     }
// }
