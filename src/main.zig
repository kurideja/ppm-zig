const std = @import("std");

const Color = extern struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
};

const light = Color{ .r = 55, .g = 11, .b = 69 };
const dark = Color{ .r = 203, .g = 163, .b = 255 };

pub fn main() !void {
    const cwd: std.fs.Dir = std.fs.cwd();

    cwd.makeDir("output") catch |e| switch (e) {
        error.PathAlreadyExists => {},
        else => return e,
    };

    var output_dir: std.fs.Dir = try cwd.openDir("output", .{});
    defer output_dir.close();

    const file: std.fs.File = try output_dir.createFile("image.ppm", .{});
    defer file.close();

    const image_h: u8 = 100;
    const image_w: u8 = 100;

    var output_writer: std.fs.File.Writer = file.writer(&.{});
    const writer: *std.Io.Writer = &output_writer.interface;

    _ = try writer.print("P6\n{d} {d}\n255\n", .{ image_w, image_h });

    for (0..image_h) |y| {
        for (0..image_w) |x| {
            var cell_color: Color = undefined;
            if ((x / 10 + y / 10) % 2 == 0) {
                cell_color = light;
            } else {
                cell_color = dark;
            }
            _ = try writer.print("{s}", .{std.mem.asBytes(&cell_color)});
        }
    }

    _ = try writer.flush();
}
