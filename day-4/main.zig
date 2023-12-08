const std = @import("std");
const ArrayList = std.ArrayList;
const allocator = std.heap.page_allocator;

fn parseSet(setString: []u8) ![]u64 {
    var set = ArrayList(u64).init(allocator);
    var setIterator = std.mem.split(u8, setString, " ");
    while (setIterator.next()) |numString| {
        if (numString.len == 0) {
            continue;
        }
        const num = try std.fmt.parseInt(u64, numString, 10);
        try set.append(num);
    }
    return set.items;
}

fn parseCard(line: []u8) !u64 {
    const cardStartIndex = std.mem.indexOf(u8, line, ":");
    if (cardStartIndex == null) {
        return 0;
    }

    const cardValues = line[(cardStartIndex orelse unreachable) + 2 ..];
    const numSeperatorIndex = std.mem.indexOf(u8, cardValues, "|");
    const winningNumbers = cardValues[0 .. (numSeperatorIndex orelse unreachable) - 1];
    const myNumbers = cardValues[(numSeperatorIndex orelse unreachable) + 2 ..];

    std.debug.print("winningNumbers: \"{s}\"\n", .{winningNumbers});
    std.debug.print("myNumbers: \"{s}\"\n", .{myNumbers});

    const parsedWinningNumbers = try parseSet(winningNumbers);
    const parsedMyNumbers = try parseSet(myNumbers);

    std.debug.print("parsedWinningNumbers: {d}\n", .{parsedWinningNumbers.len});
    std.debug.print("parsedMyNumbers: {d}\n", .{parsedMyNumbers.len});

    var accumulator: u64 = 0;

    for (parsedMyNumbers) |myNumber| {
        for (parsedWinningNumbers) |winningNumber| {
            if (myNumber == winningNumber) {
                accumulator += 1;
            }
        }
    }

    return accumulator;
}

fn updateStats(cardMatches: []u64, lineIndex: u64, numMatch: u64) void {
    for ((lineIndex + 1)..(lineIndex + numMatch)) |i| {
        cardMatches[i - 1] += 1;
    }
}

fn computeCardCount(scoreListItems: []u64) !u64 {
    var cardCounts: []u64 = try allocator.alloc(u64, scoreListItems.len - 1);

    for (1..scoreListItems.len) |lineNum| {
        cardCounts[lineNum - 1] += 1;
        for (0..cardCounts[lineNum - 1]) |_| {
            updateStats(cardCounts, lineNum, scoreListItems[lineNum - 1]);
        }
    }

    var cardCount: u64 = 0;
    for (cardCounts) |count| {
        cardCount += count;
    }

    return cardCount;
}

pub fn main() !void {
    var inputFile = try std.fs.cwd().openFile("input.txt", .{});
    defer inputFile.close();

    var buf_reader = std.io.bufferedReader(inputFile.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    var gameScore: u64 = 0;

    var scoreList = ArrayList(u64).init(allocator);
    defer scoreList.deinit();
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const value = try parseCard(line);
        std.debug.print("value: {d}\n", .{value});
        try scoreList.append(value);
        if (value != 0) gameScore += std.math.pow(u64, 2, value - 1);
    }

    const scoreListItems = scoreList.items;

    const cardCount = try computeCardCount(scoreListItems);
    std.debug.print("Pt 1: gameScore: {d}\n", .{gameScore});
    std.debug.print("Pt 2: cardCount: {d}\n", .{cardCount}); //DOES NOT WORK. I GIVE UP.
}
