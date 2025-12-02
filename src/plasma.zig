const std = @import("std");

fn dot(a: @Vector(2, f32), b: @Vector(2, f32)) f32 {
    return a[0] * b[0] + a[1] * b[1];
}
pub fn main() !void {
    const cwd = std.fs.cwd();

    cwd.makeDir("output") catch |e| switch (e) {
        error.PathAlreadyExists => {},
        else => return e,
    };

    var output_dir = try cwd.openDir("output", .{});
    defer output_dir.close();

    const image_w = 16 * 60;
    const image_h = 9 * 60;

    for (0..240) |i| {
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

        const r = @Vector(2, f32){ @floatFromInt(image_w), @floatFromInt(image_h) };

        const t = (@as(f32, @floatFromInt(i)) / 240.0) * 2.0 * std.math.pi;

        for (0..image_h) |y| {
            for (0..image_w) |x| {
                const FC: @Vector(2, f32) = .{ @floatFromInt((x)), @floatFromInt((y)) };

                const p = (FC * @Vector(2, f32){ 2.0, 2.0 } - r) / @Vector(2, f32){ r[1], r[1] };
                const l = @Vector(2, f32){ 4.0, 4.0 };
                var v = p * (l - @Vector(2, f32){ 4.0, 4.0 } * @Vector(2, f32){ @abs(0.7 - dot(p, p)), @abs(0.7 - dot(p, p)) });

                var o = @Vector(4, f32){ 0, 0, 0, 0 }; // Small non-zero value

                var iy: f32 = 1.0;
                while (iy < 8.0) : (iy += 1.0) {
                    o += (@sin(@Vector(4, f32){ v[0], v[1], v[1], v[0] }) + @Vector(4, f32){ 1.0, 1.0, 1.0, 1.0 }) *
                        @Vector(4, f32){ @abs((v[0] - v[1])), @abs((v[0] - v[1])), @abs((v[0] - v[1])), @abs((v[0] - v[1])) };
                    v += @cos(@Vector(2, f32){ v[1], v[0] } * @Vector(2, f32){ iy, iy } + @Vector(2, f32){ @floatFromInt(i), @floatFromInt(i) } * @Vector(2, f32){ t, t }) / @Vector(2, f32){ iy, iy } + @Vector(2, f32){ 0.7, 0.7 };
                }

                o = @tan(@Vector(4, f32){ 5, 5, 5, 5 } * @exp(@Vector(4, f32){ l[0], l[0], l[0], l[0] } - @Vector(4, f32){ 4, 4, 4, 4 } - @Vector(4, f32){ p[1], p[1], p[1], p[1] } * @Vector(4, f32){ -1, 1, 2, 0 }) / o);

                // Clamp output values and handle NaN/Inf
                const r_val = if (std.math.isNan(o[0]) or std.math.isInf(o[0])) 0.0 else std.math.clamp(o[0], 0.0, 1.0);
                const g_val = if (std.math.isNan(o[1]) or std.math.isInf(o[1])) 0.0 else std.math.clamp(o[1], 0.0, 1.0);
                const b_val = if (std.math.isNan(o[2]) or std.math.isInf(o[2])) 0.0 else std.math.clamp(o[2], 0.0, 1.0);

                const red: u8 = @intFromFloat(r_val * 255.0);
                const green: u8 = @intFromFloat(g_val * 255.0);
                const blue: u8 = @intFromFloat(b_val * 255.0);

                try writer.writeAll(&.{ red, green, blue });
            }
        }

        try writer.flush();
    }
}
