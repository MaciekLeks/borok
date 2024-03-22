const fmt = @import("std").fmt;
const Writer = @import("std").io.Writer;

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const VGA_SIZE = VGA_WIDTH * VGA_HEIGHT;

pub const ConsoleColors = enum(u8) {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGray = 7,
    DarkGray = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    LightMagenta = 13,
    LightBrown = 14,
    White = 15,
};

const Terminal = struct {
    row: usize,
    column: usize,
    color: u8,
    buffer: [*]volatile u16,
};

var term: Terminal = undefined;

fn vgaEntryColor(fg: ConsoleColors, bg: ConsoleColors) u8 {
    return @intFromEnum(fg) | (@intFromEnum(bg) << 4);
}

fn vgaEntry(uc: u8, new_color: u8) u16 {
    const c: u16 = new_color;

    return uc | (c << 8);
}

pub fn initialize(fg: ConsoleColors, bg: ConsoleColors) void {
    term = .{
        .row = 0,
        .column = 0,
        .color = vgaEntryColor(fg, bg),
        .buffer = @as([*]volatile u16, @ptrFromInt(0xB8000)),
    };

    clear();
}

pub fn setColor(new_color: u8) void {
    term.color = new_color;
}

pub fn clear() void {
    const buf: []volatile u16 = term.buffer[0..VGA_SIZE];
    @memset(buf, vgaEntry(' ', term.color));
}

pub fn putCharAt(c: u8, new_color: u8, x: usize, y: usize) void {
    const index = y * VGA_WIDTH + x;
    term.buffer[index] = vgaEntry(c, new_color);
}

pub fn putChar(c: u8) void {
    if (c == '\n') {
        term.row += 1;
        term.column = 0;
        return;
    }

    putCharAt(c, term.color, term.column, term.row);
    term.column += 1;
    if (term.column == VGA_WIDTH) {
        term.column = 0;
        term.row += 1;
        if (term.row == VGA_HEIGHT)
            term.row = 0;
    }
}

pub fn puts(data: []const u8) void {
    for (data) |c|
        putChar(c);
}

pub const writer = Writer(void, error{}, callback){ .context = {} };

fn callback(_: void, string: []const u8) error{}!usize {
    puts(string);
    return string.len;
}

pub fn printf(comptime format: []const u8, args: anytype) void {
    fmt.format(writer, format, args) catch unreachable;
}
