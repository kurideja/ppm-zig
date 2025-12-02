const std = @import("std");

fn dot(a: @Vector(2, f32), b: @Vector(2, f32)) f32 {
    return a[0] * b[0] + a[1] * b[1];
}

fn tanh(x: f32) f32 {
    const exp_2x = @exp(2.0 * x);
    return (exp_2x - 1.0) / (exp_2x + 1.0);
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

    const total_frames = 240;

    for (0..total_frames) |i| {
        var file_name_buf: [64]u8 = undefined;

        const output_path = try std.fmt.bufPrint(
            &file_name_buf,
            "output-{d:0>3}.ppm",
            .{i},
        );

        var file = try output_dir.createFile(output_path, .{
            .truncate = true,
            .read = false,
        });
        defer file.close();

        var buf: [4096]u8 = undefined;
        var file_writer: std.fs.File.Writer = file.writer(&buf);
        const writer: *std.Io.Writer = &file_writer.interface;

        try writer.print("P6\n{d} {d}\n255\n", .{ image_w, image_h });

        const r = @Vector(2, f32){ @floatFromInt(image_w), @floatFromInt(image_h) };

        const t = (@as(f32, @floatFromInt(i)) / 240.0) * 2 * std.math.pi;

        for (0..image_h) |y| {
            for (0..image_w) |x| {
                const FC: @Vector(2, f32) = .{ @floatFromInt((x)), @floatFromInt((y)) };

                const p = (FC * @Vector(2, f32){ 2.0, 2.0 } - r) / @Vector(2, f32){ r[1], r[1] };
                const l = @Vector(2, f32){ 4.0, 4.0 } - @Vector(2, f32){ 4.0, 4.0 } * @Vector(2, f32){ @abs(0.7 - dot(p, p)), @abs(0.7 - dot(p, p)) };
                var v = p * l;
                var loop_i = @Vector(2, f32){ 0.0, 0.0 };

                var o = @Vector(4, f32){ 0.0, 0.0, 0.0, 0.0 };

                while (loop_i[1] < 8.0) {
                    loop_i[1] += 1.0;
                    o += (@sin(@Vector(4, f32){ v[0], v[1], v[1], v[0] }) + @Vector(4, f32){ 1.0, 1.0, 1.0, 1.0 }) *
                        @Vector(4, f32){ @abs((v[0] - v[1])), @abs((v[0] - v[1])), @abs((v[0] - v[1])), @abs((v[0] - v[1])) };
                    v += @cos(@Vector(2, f32){ v[1], v[0] } * @Vector(2, f32){ loop_i[1], loop_i[1] } + loop_i + @Vector(2, f32){ t, t }) / @Vector(2, f32){ loop_i[1], loop_i[1] } + @Vector(2, f32){ 0.7, 0.7 };
                }

                o = @Vector(4, f32){
                    tanh(5.0 * @exp(l[0] - 4.0 - p[1] * -1.0) / o[0]),
                    tanh(5.0 * @exp(l[0] - 4.0 - p[1] * 1.0) / o[1]),
                    tanh(5.0 * @exp(l[0] - 4.0 - p[1] * 2.0) / o[2]),
                    0.0,
                };

                const red: u8 = @intFromFloat(o[0] * 255.0);
                const green: u8 = @intFromFloat(o[1] * 255.0);
                const blue: u8 = @intFromFloat(o[2] * 255.0);

                try writer.writeAll(&.{ red, green, blue });
            }
        }

        try writer.flush();

        std.debug.print("Generated {s}/{s} ({d:3}/{d:3})\n", .{ "output", output_path, i + 1, total_frames });
    }
}
