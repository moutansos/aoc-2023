const std = @import("std");
const ArrayList = std.ArrayList;
const allocator = std.heap.page_allocator;
const Allocator = std.mem.Allocator;

var numberWords = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

const FoundWord = struct {
    value: u8,
    position: usize,
};

fn compareFoundWord(context: void, a: FoundWord, b: FoundWord) bool {
    _ = context;
    return a.position < b.position;
}

fn findAllWordsInString(string: []u8) ![]FoundWord {
    var result = ArrayList(FoundWord).init(allocator);
    for (0..numberWords.len) |i| {
        const word = numberWords[i];
        const indexes = try indexOf(string, word);
        // const index = std.mem.indexOf(u8, string, word);
        for (indexes) |index| {
            try result.append(.{ .value = @truncate(i + 49), .position = index });
        }
    }

    return result.items;
}

fn findFirstAndLastNumberInString(line: []u8) ![]FoundWord {
    var result = ArrayList(FoundWord).init(allocator);
    var start: u8 = ' ';
    var startPosition: usize = 0;

    var end: u8 = ' ';
    var endPosition: usize = 0;

    for (0..line.len) |i| {
        const c = line[i];
        if (c >= '0' and c <= '9') {
            std.debug.print("i: {d}\n", .{i});
            start = c;
            startPosition = i;
            break;
        }
    }

    for (0..line.len) |i| {
        const j = line.len - i - 1;
        if (line[j] >= '0' and line[j] <= '9') {
            std.debug.print("j: {d}\n", .{j});
            end = line[j];
            endPosition = j;
            break;
        }
    }

    if (startPosition == endPosition) {
        try result.append(.{ .value = start, .position = startPosition });
        return result.items;
    }

    if (start != ' ') try result.append(.{ .value = start, .position = startPosition });
    if (end != ' ') try result.append(.{ .value = end, .position = endPosition });
    return result.items;
}

pub fn main() !void {
    // var inputFile = try std.fs.cwd().openFile("input.txt", .{});
    var inputFile = try std.fs.cwd().openFile("input-full.txt", .{});
    defer inputFile.close();

    var buf_reader = std.io.bufferedReader(inputFile.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    var accumulator: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        std.debug.print("line: {s}\n", .{line});
        if (line.len == 0) continue;
        const foundWords = try findAllWordsInString(line);
        const foundNumbers = try findFirstAndLastNumberInString(line);

        var allNumbers = ArrayList(FoundWord).init(allocator);
        defer allNumbers.deinit();

        try allNumbers.appendSlice(foundWords);
        try allNumbers.appendSlice(foundNumbers);

        var allNumbersSlice = allNumbers.items;
        std.debug.print("allNumbersSlice.len: {d}\n", .{allNumbersSlice.len});

        std.sort.insertion(FoundWord, allNumbersSlice, {}, compareFoundWord);

        if (allNumbersSlice.len == 0) continue;

        const last = allNumbers.getLast();
        const first = allNumbers.items[0];

        const start = first.value;
        const end = last.value;

        const number = try std.fmt.allocPrint(allocator, "{c}{c}", .{ start, end });
        std.debug.print("number: {s}\n", .{number});
        const numberAsInt = try std.fmt.parseInt(u32, number, 10);
        accumulator += numberAsInt;
    }

    std.debug.print("grand total: {d}\n", .{accumulator});
}

fn indexOf(haystack: []const u8, needle: []const u8) ![]usize {
    var indexes = ArrayList(usize).init(allocator);
    for (haystack, 0..) |b, i| {
        _ = b;
        if (std.mem.startsWith(u8, haystack[i..], needle)) {
            try indexes.append(i);
        }
    }
    return indexes.items;
}
