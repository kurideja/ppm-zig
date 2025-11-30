const std = @import("std");

pub fn main() !void {
    const cwd = std.fs.cwd();

    cwd.makeDir("output") catch |e| switch (e) {
        error.PathAlreadyExists => {},
        else => return e,
    };

    var output_dir = try cwd.openDir("output", .{});
    defer output_dir.close();

    const image_w = 100;
    const image_h = 100;

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

        const r = @Vector(2, f32){ @floatFromInt(image_w), @floatFromInt(image_h) };

        for (0..image_h) |y| {
            for (0..image_w) |x| {
                const FC: @Vector(2, f32) = .{ @floatFromInt((x)), @floatFromInt((y)) };

                const p = (FC * @Vector(2, f32){ 2.0, 2.0 } - r) / @Vector(2, f32){ r[1], r[1] };
                const t: f32 = @as(u32, i) / 60.0;

                // l,
                // i,
                // v=p*(l+=4.-4.*abs(.7-dot(p,p)));
                // for(;i.y++<8.;o+=(sin(v.xyyx)+1.)*abs(v.x-v.y))v+=cos(v.yx*i.y+i+t)/i.y+.7;o=tanh(5.*exp(l.x-4.-p.y*vec4(-1,1,2,0))/o);
            }
        }

        try writer.flush();
    }
}
