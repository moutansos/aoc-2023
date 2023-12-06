const std = @import("std");
const ArrayList = std.ArrayList;
const allocator = std.heap.page_allocator;

const FoundNumber = struct {
    number: u64,
    xStartPosition: usize,
    xEndPosition: usize,
    yposition: usize,
};

const Point = struct {
    x: usize,
    y: usize,
};

const Rect = struct {
    lTop: Point,
    lBottom: Point,
    rTop: Point,
    rBottom: Point,

    pub fn contains(self: Rect, p: Point) bool {
        return p.x >= self.lTop.x and p.x <= self.rTop.x and p.y >= self.lTop.y and p.y <= self.lBottom.y;
    }
};

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn findAllNumbers(lines: [][]u8) ![]FoundNumber {
    var foundNumbers = ArrayList(FoundNumber).init(allocator);
    for (0..lines.len) |y| {
        var line = lines[y];
        std.debug.print("\nline {d}: {s}\n", .{ y, line });
        var numberStartIndex: ?usize = null;
        var numberEndIndex: ?usize = null;

        for (0..line.len) |x| {
            var c = line[x];
            if (isDigit(c)) {
                std.debug.print("found digit {c} at position x: {?d} y: {?d}\n", .{ c, x, y });
                if (numberStartIndex == null) {
                    numberStartIndex = x;
                }
            }
            std.debug.print("numberStartIndex: {?d}\n", .{numberStartIndex});
            const isEndOfLine = x == line.len - 1;
            if ((!isDigit(c) or isEndOfLine) and numberStartIndex != null) {
                numberEndIndex = if (isEndOfLine and isDigit(c)) x else x - 1;
                std.debug.print("found end of number at position x: {?d} y: {?d}\n", .{ numberEndIndex, y });
                const start = numberStartIndex orelse unreachable;
                const end = numberEndIndex orelse unreachable;
                const parsedInt = try std.fmt.parseInt(u32, line[start .. end + 1], 10);
                std.debug.print("parsedInt: {d}\n", .{parsedInt});
                try foundNumbers.append(FoundNumber{
                    .number = parsedInt,
                    .xStartPosition = start,
                    .xEndPosition = end,
                    .yposition = y,
                });
                numberStartIndex = null;
                numberEndIndex = null;
            }
        }
    }

    return foundNumbers.items;
}

fn findGearRatio(schematic: [][]u8, gearCandidateX: usize, gearCandidateY: usize, foundNumbers: []FoundNumber) !?u64 {
    const xMin = @max(0, gearCandidateX - 1);
    const xMax = if (gearCandidateX + 1 >= schematic[gearCandidateY].len) schematic[gearCandidateY].len - 1 else gearCandidateX + 1;
    const yMin = @max(0, gearCandidateY - 1);
    const yMax = if (gearCandidateY + 1 >= schematic.len) schematic.len - 1 else gearCandidateY + 1;

    const candidateGearRect = Rect{
        .lTop = Point{ .x = xMin, .y = yMin },
        .lBottom = Point{ .x = xMin, .y = yMax },
        .rTop = Point{ .x = xMax, .y = yMin },
        .rBottom = Point{ .x = xMax, .y = yMax },
    };

    std.debug.print("xMin: {d} xMax: {d} yMin: {d} yMax: {d}\n", .{ xMin, xMax, yMin, yMax });

    var adjacentNumbers: ArrayList(u64) = ArrayList(u64).init(allocator);
    defer adjacentNumbers.deinit();

    for (0..foundNumbers.len) |i| {
        var number = foundNumbers[i];

        std.debug.print("xStartPosition: {d} xEndPosition: {d} yposition: {d}\n", .{ number.xStartPosition, number.xEndPosition, number.yposition });
        for (number.xStartPosition..number.xEndPosition + 1) |x| {
            std.debug.print("checking if number is adjacent to gear candidate. Position: {d},{d}  number: {d}\n", .{ x, number.yposition, number.number });
            if (candidateGearRect.contains(Point{ .x = x, .y = number.yposition })) {
                if (std.mem.indexOf(u64, adjacentNumbers.items, &[_]u64{number.number}) == null) {
                    std.debug.print("found adjacent number: {d}\n", .{number.number});
                    try adjacentNumbers.append(number.number);
                }
            }
        }
    }

    if (adjacentNumbers.items.len != 2) {
        return null;
    }
    const g1 = adjacentNumbers.items[0];
    const g2 = adjacentNumbers.items[1];

    return g1 * g2;
}

fn totalGearRatios(schematic: [][]u8, foundNumbers: []FoundNumber) !u64 {
    var gearRatioAccumulator: u64 = 0;
    for (0..schematic.len) |y| {
        std.debug.print("\ngr line {d}: {s}\n", .{ y, schematic[y] });
        var line = schematic[y];
        for (0..line.len) |x| {
            var c = line[x];
            if (c == '*') {
                std.debug.print("found possible gear ratio at position x: {?d} y: {?d}\n", .{ x, y });
                var gearRatio = try findGearRatio(schematic, x, y, foundNumbers);
                if (gearRatio != null) {
                    std.debug.print("found gear ratio: {?d}\n", .{gearRatio});
                    gearRatioAccumulator += gearRatio orelse unreachable;
                }
            }
        }
    }

    return gearRatioAccumulator;
}

fn isSymbol(c: u8) bool {
    return !isDigit(c) and c != '.';
}

fn isPartNumber(schematic: [][]u8, number: FoundNumber) bool {
    std.debug.print("\nchecking if number is part number. Position: {d},{d}  number: {d}\n", .{ number.xStartPosition, number.yposition, number.number });
    if (number.xStartPosition != 0 and isSymbol(schematic[number.yposition][number.xStartPosition - 1])) {
        std.debug.print("found symbol to the left of number\n", .{});
        return true;
    }
    if (number.xEndPosition != schematic[number.yposition].len - 1 and isSymbol(schematic[number.yposition][number.xEndPosition + 1])) {
        std.debug.print("found symbol to the right of number\n", .{});
        return true;
    }

    const xIterStart = if (number.xStartPosition == 0) 0 else number.xStartPosition - 1;
    const xIterEnd = if (number.xEndPosition == schematic[number.yposition].len - 1) schematic[number.yposition].len else number.xEndPosition + 2;

    if (number.yposition != 0) {
        for (xIterStart..xIterEnd) |x| {
            if (isSymbol(schematic[number.yposition - 1][x])) {
                std.debug.print("found symbol above number\n", .{});
                return true;
            }
        }
    }

    if (number.yposition != schematic.len - 1) {
        for (xIterStart..xIterEnd) |x| {
            if (isSymbol(schematic[number.yposition + 1][x])) {
                std.debug.print("found symbol below number\n", .{});
                return true;
            }
        }
    }

    return false;
}

pub fn main() !void {
    var inputFile = try std.fs.cwd().openFile("input-full.txt", .{});
    defer inputFile.close();

    var buf_reader = std.io.bufferedReader(inputFile.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    var lines = ArrayList([]u8).init(allocator);
    defer lines.deinit();
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            continue;
        }
        var newArray: []u8 = try allocator.alloc(u8, line.len);
        std.mem.copy(u8, newArray, line[0..line.len]);
        try lines.append(newArray);
    }

    const fullMap = lines.items;
    const foundNumbers = try findAllNumbers(fullMap);

    std.debug.print("foundNumbers: {d}\n", .{foundNumbers.len});

    var part1Accumulator: u64 = 0;
    for (0..foundNumbers.len) |i| {
        var partNumber = foundNumbers[i];
        if (isPartNumber(fullMap, partNumber)) {
            part1Accumulator += partNumber.number;
        }
    }

    const gearRatio = try totalGearRatios(fullMap, foundNumbers);
    std.debug.print("Part 1: {}\n", .{part1Accumulator});
    std.debug.print("Part 2: {}\n", .{gearRatio});
}
