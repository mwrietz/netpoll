const std = @import("std");
const net = std.net;
const os = std.os;

pub fn getIPv4() ![]const u8 {
    const sock: i32 = @intCast(os.linux.socket(os.linux.AF.INET, os.linux.SOCK.DGRAM, 0));
    defer _ = os.linux.close(sock);

    // Connect to a public DNS server to get local interface
    const addr = try net.Address.parseIp4("8.8.8.8", 53);
    _ = os.linux.connect(sock, &addr.any, addr.getOsSockLen());

    // Get local address information
    var local_addr: os.linux.sockaddr.in = undefined;
    var local_addr_len: os.linux.socklen_t = @sizeOf(os.linux.sockaddr.in);
    _ = os.linux.getsockname(sock, @ptrCast(&local_addr), &local_addr_len);

    // Convert IP address to string
    const first: u8 = @intCast(local_addr.addr & 0xFF);
    const second: u8 = @intCast((local_addr.addr >> 8) & 0xFF);
    const third: u8 = @intCast((local_addr.addr >> 16) & 0xFF);
    const fourth: u8 = @intCast((local_addr.addr >> 24) & 0xFF);

    var ip_buffer: [15]u8 = undefined;
    const ip_str = try std.fmt.bufPrint(&ip_buffer, "{}.{}.{}.{}", .{ first, second, third, fourth });

    return ip_str;
}

pub fn getMyNetIPv4() ![]const u8 {
    const sock: i32 = @intCast(os.linux.socket(os.linux.AF.INET, os.linux.SOCK.DGRAM, 0));
    defer _ = os.linux.close(sock);

    // Connect to a public DNS server to get local interface
    const addr = try net.Address.parseIp4("8.8.8.8", 53);
    _ = os.linux.connect(sock, &addr.any, addr.getOsSockLen());

    // Get local address information
    var local_addr: os.linux.sockaddr.in = undefined;
    var local_addr_len: os.linux.socklen_t = @sizeOf(os.linux.sockaddr.in);
    _ = os.linux.getsockname(sock, @ptrCast(&local_addr), &local_addr_len);

    // Convert IP address to string
    const first: u8 = @intCast(local_addr.addr & 0xFF);
    const second: u8 = @intCast((local_addr.addr >> 8) & 0xFF);
    const third: u8 = @intCast((local_addr.addr >> 16) & 0xFF);

    var ip_buffer: [15]u8 = undefined;
    const ip_str = try std.fmt.bufPrint(&ip_buffer, "{}.{}.{}.*", .{ first, second, third });

    return ip_str;
}
