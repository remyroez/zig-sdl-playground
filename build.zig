const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("hello", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    const vcpkg = b.option(bool, "vcpkg", "Add vcpkg paths to the build") orelse exe.target.isWindows();
    if (vcpkg) {
        exe.addVcpkgPaths(.dynamic) catch @panic("Cannot add vcpkg paths.");
        if (exe.target.isWindows()) {
            if (exe.vcpkg_bin_path) |path| {
                installBinFiles(b, path, &.{
                    "SDL2.dll",
                    "SDL2_image.dll",
                    //"turbojpeg.dll",
                    //"jpeg62.dll",
                    //"tiff.dll",
                    //"webp.dll",
                    "libpng16.dll",
                    "zlib1.dll",
                    "SDL2_mixer.dll",
                    "ogg.dll",
                    "vorbis.dll",
                    "vorbisfile.dll",
                    "SDL2_ttf.dll",
                    "freetype.dll",
                    "bz2.dll",
                    "brotlidec.dll",
                    "brotlicommon.dll",
                });
            }
        }
    }

    if (exe.target.isWindows()) {
        //exe.subsystem = .Windows;
        //exe.linkSystemLibrary("Shell32");
    }

    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_image");
    exe.linkSystemLibrary("SDL2_mixer");
    exe.linkSystemLibrary("SDL2_ttf");

    exe.linkLibC();

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}

fn installBinFiles(b: *std.build.Builder, path: []const u8, files: []const []const u8) void {
    for (files) |file| {
        b.installBinFile(b.pathJoin(&.{ path, file }), file);
    }
}
