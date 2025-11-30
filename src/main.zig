const std = @import("std");

pub fn main() !void {
    const cwd = std.fs.cwd();

    cwd.makeDir("output") catch |e| switch (e) {
        error.PathAlreadyExists => {},
        else => return e,
    };

    var output_dir = try cwd.openDir("output", .{});
    defer output_dir.close();

    const image_w: usize = 100;
    const image_h: usize = 100;

    const light: [3]u8 = .{ 200, 200, 200 };
    const dark: [3]u8 = .{ 50, 50, 50 };

    for (0..100) |i| {
        var file_name_buf: [64]u8 = undefined; // temp buffer for filename

        const filename = try std.fmt.bufPrint(
            &file_name_buf,
            "output-{d:0>2}.ppm", // {d:0>2} = zero-padded width 2
            .{i},
        );

        var file = try output_dir.createFile(filename, .{
            .truncate = true,
            .read = false,
        });
        defer file.close();

        var buf: [4096]u8 = undefined; // or use &.{} for unbuffered
        var file_writer: std.fs.File.Writer = file.writer(&buf);
        const writer: *std.Io.Writer = &file_writer.interface;

        try writer.print("P6\n{d} {d}\n255\n", .{ image_w, image_h });

        for (0..image_h) |y| {
            for (0..image_w) |x| {
                const cell_color =
                    if (((x + i) / 10 + (y + i) / 10) % 2 == 0) light else dark;

                try writer.writeAll(std.mem.asBytes(&cell_color));
            }
        }

        try writer.flush();
    }
}
