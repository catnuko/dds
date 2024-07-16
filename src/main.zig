const print = @import("std").debug.print;
const std = @import("std");
const json = std.json;
const DDS = @cImport({
    @cInclude("dds.h");
});
const MyError = error{
    FAILED,
};
pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);
    if (args.len < 2) return error.ExpectedArgument;
    const inputFileName = args[1];

    // const img = DDS.dds_load_from_file("/home/catnuko/voxel-render/public/volume.dds");
    const img = DDS.dds_load_from_file(inputFileName);
    if(img == null){
        try stdout.print("无法解析文件,{s}\n",.{inputFileName});
        return MyError.FAILED;
    }
    defer DDS.dds_image_free(img);
    const header = img.*.header;
    const is3D = header.caps2 & DDS.DDSCAPS2_VOLUME != 0;
    const width = header.width;
    const height = header.height;
    const depth = header.depth;
    try stdout.print("is3D:{}\n",.{is3D});
    try stdout.print("{}\n",.{header});
    try stdout.print("size is {}x{}x{}\n",.{width,height,depth});
    const pixels = img.*.pixels;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _=gpa.deinit();
    const allocator = gpa.allocator();
    const len = width*height*depth*4;
    const bytes = try allocator.alloc(u8, len);
    defer allocator.free(bytes);

    for(0..len)|i|{
        bytes[i] = pixels[i];
    }

    const fileName =try std.fmt.allocPrint(allocator,"volume_{d}x{d}x{d}_uint8_rgba.raw",.{width,height,depth});
    defer allocator.free(fileName);
    try stdout.print("已解析，{s} => {s}\n",.{inputFileName,fileName});
    const file = try std.fs.cwd().createFile(fileName,.{.read=true});
    defer file.close();

    try file.writeAll(bytes);
}