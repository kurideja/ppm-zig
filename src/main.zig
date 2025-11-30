const std = @import("std");

pub fn main() !void {
    const cwd = std.fs.cwd();

    cwd.makeDir("output") catch |e| switch (e) {
        error.PathAlreadyExists => {},
        else => return e,
    };

    var output_dir = try cwd.openDir("output", .{});
    defer output_dir.close();

    var file = try output_dir.createFile("image.ppm", .{
        .truncate = true,
        .read = false,
    });
    defer file.close();

    const image_w: usize = 100;
    const image_h: usize = 100;

    var buf: [4096]u8 = undefined; // or use &.{} for unbuffered
    var file_writer: std.fs.File.Writer = file.writer(&buf);
    const writer: *std.Io.Writer = &file_writer.interface;

    try writer.print("P6\n{d} {d}\n255\n", .{ image_w, image_h });

    const light: [3]u8 = .{ 200, 200, 200 };
    const dark: [3]u8 = .{ 50, 50, 50 };

    for (0..image_h) |y| {
        for (0..image_w) |x| {
            const cell_color =
                if ((x / 10 + y / 10) % 2 == 0) light else dark;

            try writer.writeAll(std.mem.asBytes(&cell_color));
        }
    }

    try writer.flush();
}
