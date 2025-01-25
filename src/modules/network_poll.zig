const std = @import("std");
const mn = @import("mynet.zig");
const zth = @import("zig-tui-helpers.zig");
const ansi = @import("ansi.zig");
const Child = std.process.Child;

const RunError = error{
    Failed,
};

pub fn network_poll() !void {
    try network_poll_up();
}

pub fn network_poll_all() !void {
    const stdout = std.io.getStdOut().writer();
    try ansi.Cursor.to(stdout, 0, 2);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var ip_list = std.ArrayList([]const u8).init(alloc);
    defer ip_list.deinit();

    var hostname_map = std.StringHashMap([]const u8).init(alloc);
    defer hostname_map.deinit();

    const my_net_ip_range = try mn.getMyNetIPv4();

    const out_all = try callCommand(alloc, &[_][]const u8{ "nmap", "-sn", "-Pn", my_net_ip_range });
    defer out_all.deinit();

    var lines_all = std.mem.split(u8, out_all.items, "\n");

    const allocator_all = std.heap.page_allocator;

    // + push all ip addresses from "all" list (ip's with hostnames)
    while (lines_all.next()) |line_all| {
        if (strBeginsWith(line_all, "Nmap scan")) {
            var word_list_all = try sentenceToWords(allocator_all, line_all);
            defer word_list_all.deinit();

            // print devices that include a hostname
            if (word_list_all.items.len == 6) {
                const ip = std.mem.trim(u8, word_list_all.items[5], "()");
                try ip_list.append(ip);

                try hostname_map.put(ip, word_list_all.items[4]);
            }
        }
    }

    const deduped_ip_list = try dedupAndSortStrings(alloc, ip_list);
    defer {
        for (deduped_ip_list.items) |item| {
            alloc.free(item);
        }
        deduped_ip_list.deinit();
    }

    var count: u32 = 0;
    for (deduped_ip_list.items) |ip| {
        count += 1;
        const hostname = hostname_map.get(ip);
        zth.printColor("    {:3}:  ", .{count}, "gray");
        zth.print("{s:<16} {?s}\n", .{ ip, hostname });
        try ansi.Cursor.to(stdout, 0, null);
    }
}

pub fn network_poll_up() !void {
    const stdout = std.io.getStdOut().writer();
    try ansi.Cursor.to(stdout, 0, 2);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    // create ArrayList of ip addresses
    var ip_list = std.ArrayList([]const u8).init(alloc);
    defer ip_list.deinit();

    // create HashMap of hostnames
    var hostname_map = std.StringHashMap([]const u8).init(alloc);
    defer hostname_map.deinit();

    // get my ip address and format with last char = '*'
    const my_net_ip_range = try mn.getMyNetIPv4();

    // const out_all = try callCommand(alloc_all, &[_][]const u8{ "nmap", "-sn", "-Pn", my_net_ip_range_all });
    // defer out_all.deinit();
    //
    // // split output into lines iterator
    // var lines_all = std.mem.split(u8, out_all.items, "\n");
    //
    // const allocator_all = std.heap.page_allocator;
    //
    // // + push all ip addresses from "all" list (ip's with hostnames)
    // while (lines_all.next()) |line_all| {
    //     // zth.print("line_all: {s}\n", .{line_all});
    //     // try ansi.Cursor.to(stdout, 0, null);
    //     if (strBeginsWith(line_all, "Nmap scan")) {
    //
    //         // parse line
    //         //const allocator = std.heap.page_allocator;
    //         var word_list_all = try sentenceToWords(allocator_all, line_all);
    //         defer word_list_all.deinit();
    //
    //         // // ********* print devices that don't include a hostname
    //         // if (wordList.items.len == 5) {
    //         //     //std.debug.print("{:2}: {s:<16}\n", .{ count, wordList.items[4] });
    //         //     const ip = wordList.items[4];
    //         //     try ip_list.append(ip);
    //         // }
    //
    //         // print devices that include a hostname
    //         if (word_list_all.items.len == 6) {
    //
    //             // add ip address to list
    //             const ip = std.mem.trim(u8, word_list_all.items[5], "()");
    //             try ip_list.append(ip);
    //
    //             // add ip and hostname to hashmap
    //             try hostname_map.put(ip, word_list_all.items[4]);
    //         }
    //     }
    // }
    // // zth.print("ip_list: {}\n", .{ip_list});
    // // try ansi.Cursor.to(stdout, 0, null);
    // //
    // // // delay 10 seconds before calling nmap again
    // // zth.print("Delaying 10 seconds...\n", .{});
    // // try ansi.Cursor.to(stdout, 0, null);
    // // std.time.sleep(10 * std.time.ns_per_s);

    const out_up = try callCommand(alloc, &[_][]const u8{ "nmap", "-sn", my_net_ip_range });
    defer out_up.deinit();

    // split output into lines iterator
    var lines_up = std.mem.split(u8, out_up.items, "\n");
    // zth.print("lines_up: {}\n", .{lines_up});
    // try ansi.Cursor.to(stdout, 0, null);
    // zth.print("lines_all: {}\n", .{lines_all});
    // try ansi.Cursor.to(stdout, 0, null);

    const allocator_up = std.heap.page_allocator;

    // push all ip addresses from "up" list
    while (lines_up.next()) |line_up| {
        // zth.print("line_up: {s}\n", .{line_up});
        // try ansi.Cursor.to(stdout, 0, null);
        if (strBeginsWith(line_up, "Nmap scan")) {

            // parse line
            //const allocator = std.heap.page_allocator;
            var word_list_up = try sentenceToWords(allocator_up, line_up);
            defer word_list_up.deinit();

            //print devices that don't include a hostname
            //zth.print("word_list_up: {}\n", .{word_list_up});
            if (word_list_up.items.len == 5) {
                const ip = word_list_up.items[4];
                // zth.print("debug ip: {s}\n", .{ip});
                // try ansi.Cursor.to(stdout, 0, null);
                try ip_list.append(ip);
                //std.debug.print("{:2}: {s:<16}\n", .{ count, wordList.items[4] });
            }

            // print devices that include a hostname
            if (word_list_up.items.len == 6) {

                // add ip address to list
                const ip = std.mem.trim(u8, word_list_up.items[5], "()");
                try ip_list.append(ip);

                // add ip and hostname to hashmap
                try hostname_map.put(ip, word_list_up.items[4]);
            }
        }
    }
    // zth.print("ip_list: {}\n", .{ip_list});
    // try ansi.Cursor.to(stdout, 0, null);
    // for (ip_list.items) |ips| {
    //     zth.print("ips: {s}\n", .{ips});
    //     try ansi.Cursor.to(stdout, 0, null);
    // }

    // sort and deduplicate arraylist
    const deduped_ip_list = try dedupAndSortStrings(alloc, ip_list);
    defer {
        for (deduped_ip_list.items) |item| {
            alloc.free(item);
        }
        deduped_ip_list.deinit();
    }

    // print results
    var count: u32 = 0;
    for (deduped_ip_list.items) |ip| {
        count += 1;
        const hostname = hostname_map.get(ip);
        zth.printColor("    {:3}:  ", .{count}, "gray");
        zth.print("{s:<16} {?s}\n", .{ ip, hostname });
        try ansi.Cursor.to(stdout, 0, null);
    }

    // zth.print("out_all: {}\n", .{out_all});
    // try ansi.Cursor.to(stdout, 0, null);
    // zth.print("out_up: {}\n", .{out_up});
    // try ansi.Cursor.to(stdout, 0, null);
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
