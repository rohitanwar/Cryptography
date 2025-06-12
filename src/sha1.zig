const std = @import("std");

const Message = struct {
    num_chunks: u64,
    message: []const u1,
    chunks: []const [16]u32,
};

const MessageError = error{InvalidLength};

pub fn main() !void {
    const ziggy = "I'll be back";
    const allocator = std.heap.page_allocator;
    const bits = try strToBits(allocator, @constCast(ziggy));

    const message = try paddedMessage(allocator, bits);
    defer allocator.free(message);

    const msg = try makeMessageStruct(allocator, message);

    const stdout = std.io.getStdOut().writer();
    const output = calculateSHA(msg);

    for (output) |hashElement| {
        _ = try stdout.print("{x:0>8}", .{hashElement});
    }

    try stdout.print("\n", .{});
}

// Also pads a 1 to it.
fn strToBits(allocator: std.mem.Allocator, str: []u8) ![]u1 {
    var bits = try allocator.alloc(u1, str.len * 8 + 1);

    for (str, 0..) |c, i| {
        var b: u3 = 0;
        while (b < 7) : (b += 1) {
            bits[i * 8 + b] = @truncate((c >> (7 - b)) & 1);
        }
        bits[i * 8 + 7] = @truncate((c >> 0) & 1);
    }

    bits[bits.len - 1] = 1;

    return bits;
}

fn paddedMessage(allocator: std.mem.Allocator, bits: []u1) ![]u1 {
    const old_length = bits.len;
    const new_length = old_length + 64 + 512 - (old_length + 64) % 512; //64 bit -> length at end
    var message: []u1 = try allocator.realloc(bits, new_length);

    var s: u6 = 0;
    while (s < 63) : (s += 1) {
        message[new_length - s - 1] = @truncate(((old_length - 1) >> s) & 1); // -1 for the 1 padded bit
    }

    message[new_length - 63 - 1] = @truncate(((old_length - 1) >> 63) & 1); // -1 for the 1 padded bit

    return message;
}

fn makeMessageStruct(allocator: std.mem.Allocator, message: []const u1) !Message {
    if (message.len % 512 != 0) {
        return MessageError.InvalidLength;
    }

    const num_chunks = message.len / 512;

    var chunks = try allocator.alloc([16]u32, num_chunks);

    for (0..num_chunks) |i| {
        for (0..16) |j| {
            var temp: u32 = 0;

            var s: u5 = 0;

            while (s < 31) : (s += 1) {
                temp = (temp << 1) | message[i * 32 * 16 + j * 32 + s];
            }

            temp = (temp << 1) | message[i * 32 * 16 + j * 32 + 31];

            chunks[i][j] = temp;
        }
    }

    return Message{
        .num_chunks = num_chunks,
        .message = message,
        .chunks = chunks,
    };
}

fn circularShift(n: u5, X: u32) u32 {
    switch (n) {
        0 => return X,
        else => return (X << n) | (X >> (31 - (n - 1))),
    }
}

fn specialF(t: u7, B: u32, C: u32, D: u32) u32 {
    switch (t) {
        0...19 => return (B & C) | ((~B) & D),
        20...39 => return B ^ C ^ D,
        40...59 => return (B & C) | (B & D) | (C & D),
        60...80 => return B ^ C ^ D,
        else => unreachable,
    }
}

fn calculateSHA(msg: Message) [5]u32 {
    var H0: u32 = 0x67452301;
    var H1: u32 = 0xEFCDAB89;
    var H2: u32 = 0x98BADCFE;
    var H3: u32 = 0x10325476;
    var H4: u32 = 0xC3D2E1F0;

    const Konstants: [4]u32 = .{
        0x5A827999,
        0x6ED9EBA1,
        0x8F1BBCDC,
        0xCA62C1D6,
    };
    for (msg.chunks) |chunk| {
        var words: [80]u32 = undefined;
        std.mem.copyForwards(u32, words[0..16], &chunk);

        for (16..80) |i| {
            words[i] = circularShift(1, words[i - 3] ^ words[i - 8] ^ words[i - 14] ^ words[i - 16]);
        }

        var A = H0;
        var B = H1;
        var C = H2;
        var D = H3;
        var E = H4;
        var t: u7 = 0;
        while (t < 80) : (t += 1) {
            var temp = @addWithOverflow(circularShift(5, A), specialF(t, B, C, D))[0];
            temp = @addWithOverflow(temp, E)[0];
            temp = @addWithOverflow(temp, words[t])[0];
            temp = @addWithOverflow(temp, Konstants[t / 20])[0]; // basically 0..20 -> 0, 20..40 -> 1, etc.. (hopefully better than using an if statement)
            E = D;
            D = C;
            C = circularShift(30, B);
            B = A;
            A = temp;
        }

        H0 = @addWithOverflow(H0, A)[0];
        H1 = @addWithOverflow(H1, B)[0];
        H2 = @addWithOverflow(H2, C)[0];
        H3 = @addWithOverflow(H3, D)[0];
        H4 = @addWithOverflow(H4, E)[0];
    }

    return .{ H0, H1, H2, H3, H4 };
}
