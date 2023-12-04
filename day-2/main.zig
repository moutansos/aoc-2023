const std = @import("std");
const ArrayList = std.ArrayList;
const allocator = std.heap.page_allocator;

const GameSet = struct {
    red: u32,
    blue: u32,
    green: u32,
};

const Game = struct {
    id: u32,
    sets: []GameSet,
};

fn parseGame(line: []const u8) !Game {
    const indexOfColon = std.mem.indexOf(u8, line, ":") orelse 0;
    const idHalfOfString = line[0..indexOfColon];
    const indexofSpace = std.mem.indexOf(u8, idHalfOfString, " ") orelse 0;
    const idString = idHalfOfString[indexofSpace + 1 ..];
    const id = try std.fmt.parseInt(u32, idString, 10);

    const setsString = line[indexOfColon + 1 ..];

    var sets = ArrayList(GameSet).init(allocator);
    var setIterator = std.mem.split(u8, setsString, ";");
    while (setIterator.next()) |setString| {
        var set = GameSet{
            .red = 0,
            .blue = 0,
            .green = 0,
        };
        var cubeIterator = std.mem.split(u8, setString, ",");
        while (cubeIterator.next()) |cubeString| {
            const cleanCubeString = cubeString[1..];
            const indexOfSpace = std.mem.indexOf(u8, cleanCubeString, " ") orelse 0;
            const numberOfCubes = try std.fmt.parseInt(u32, cleanCubeString[0..indexOfSpace], 10);
            const color = cleanCubeString[indexOfSpace + 1 ..];

            if (std.mem.eql(u8, color, "red")) {
                set.red = numberOfCubes;
            } else if (std.mem.eql(u8, color, "blue")) {
                set.blue = numberOfCubes;
            } else if (std.mem.eql(u8, color, "green")) {
                set.green = numberOfCubes;
            } else {
                std.debug.print("unknown color: \"{s}\"\n", .{color});
            }
        }

        try sets.append(set);
    }

    return Game{
        .id = id,
        .sets = sets.items,
    };
}

fn isGameValid(game: Game) bool {
    for (game.sets) |set| {
        if (set.red > 12) {
            return false;
        } else if (set.blue > 14) {
            return false;
        } else if (set.green > 13) {
            return false;
        }
    }

    return true;
}

fn computeMinimumSet(game: Game) GameSet {
    var red: u32 = 0;
    var blue: u32 = 0;
    var green: u32 = 0;

    for (game.sets) |set| {
        if (set.red > red) {
            red = set.red;
        }

        if (set.blue > blue) {
            blue = set.blue;
        }

        if (set.green > green) {
            green = set.green;
        }
    }

    return GameSet{
        .red = red,
        .blue = blue,
        .green = green,
    };
}

fn computePowerOfMiniumSet(game: Game) u128 {
    const minSet = computeMinimumSet(game);
    std.debug.print("minSet: {d} red {d} blue {d} green\n", .{ minSet.red, minSet.blue, minSet.green });
    const bigRed: u128 = minSet.red;
    const bigBlue: u128 = minSet.blue;
    const bigGreen: u128 = minSet.green;

    return bigRed * bigBlue * bigGreen;
}

pub fn main() !void {
    var inputFile = try std.fs.cwd().openFile("input-full.txt", .{});
    defer inputFile.close();

    var buf_reader = std.io.bufferedReader(inputFile.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    var validAccumulator: u32 = 0;
    var powerAccumulator: u128 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        std.debug.print("line: \"{s}\"\n", .{line});
        if (line.len == 0) {
            continue;
        }
        const game = try parseGame(line);
        if (isGameValid(game)) {
            validAccumulator += game.id;
        }

        powerAccumulator += computePowerOfMiniumSet(game);
    }
    std.debug.print("Valid Game Total: {d}\n", .{validAccumulator});
    std.debug.print("Power Total: {d}\n", .{powerAccumulator});
}
