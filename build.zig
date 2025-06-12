const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create executable for SHA-1
    const sha1_exe = b.addExecutable(.{
        .name = "sha1",
        .root_source_file = .{ .path = "src/sha1.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Install executable
    b.installArtifact(sha1_exe);

    // Create run step
    const run_sha1 = b.addRunArtifact(sha1_exe);
    if (b.args) |args| {
        run_sha1.addArgs(args);
    }

    const run_step = b.step("run", "Run the SHA-1 implementation");
    run_step.dependOn(&run_sha1.step);

    // Create tests
    // const sha1_tests = b.addTest(.{
    //     .root_source_file = .{ .path = "src/sha1.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&sha1_tests.step);
}
