const std = @import("std");

const Message = struct {
    num_chunks: u64,
    message: []const u1,
    chunks: [][512]u1,
};

const MessageError = error{InvalidLength};

pub fn main() !void {
    const ziggy = "stardustbruh";

    const allocator = std.heap.page_allocator;
    const bits = try strToBits(allocator, @constCast(ziggy));
    const message = try paddedMessage(allocator, bits);
    defer allocator.free(message);

    const msg = try makeMessageStruct(message);
    const stdout = std.io.getStdOut().writer();
    for (0..message.len / 8) |i| {
        for (0..8) |j| {
            _ = try stdout.print("{d}", .{message[i * 8 + j]});
        }
        _ = try stdout.print(" ", .{});
    }
    _ = try stdout.print("\n", .{});

    std.debug.print("{d}", .{ziggy});
}

fn strToBits(allocator: std.mem.Allocator, str: []u8) ![]u1 {
    var bits = try allocator.alloc(u1, str.len * 8);

    for (str, 0..) |c, i| {
        var b: u3 = 0;
        while (b < 7) : (b += 1) {
            bits[i * 8 + b] = @truncate((c >> (7 - b)) & 1);
        }
        bits[i * 8 + 7] = @truncate((c >> 0) & 1);
    }

    return bits;
}

fn paddedMessage(allocator: std.mem.Allocator, bits: []u1) ![]u1 {
    const old_length = bits.len;
    const new_length = old_length + 512 - old_length % 512;

    var message: []u1 = try allocator.realloc(bits, new_length);
    message[old_length] = 1;

    std.debug.print("here", .{});
    var s: u6 = 0;
    while (s < 63) : (s += 1) {
        message[new_length - s - 1] = @truncate((old_length >> s) & 1);
    }

    message[new_length - 63 - 1] = @truncate((old_length >> 63) & 1);

    return message;
}

fn makeMessageStruct(message: []const u1) !Message {
    if (message.len % 512 != 0) {
        return MessageError.InvalidLength;
    }

    const num_chunks = message.len / 512;

    const chunks: [][512]u1 = @as([][512]u1, @ptrCast(message.ptr))[0..num_chunks];

    return Message{
        .message = message,
        .chunks = chunks,
    };
}
