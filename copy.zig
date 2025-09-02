const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard build options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseFast,
    });

    // ---- Static library: kafka ----
    const lib = b.addLibrary(.{
        .name = "kafka",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/kafka.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    b.installArtifact(lib);

    // ---- Module: kafka ----
    const kafkazig = b.createModule(.{
        .root_source_file = b.path("src/kafka.zig"),
        .link_libc = true,
    });

    // ---- Executable: kafka ----
    const exe = b.addExecutable(.{
        .name = "kafka",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/kafka.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    exe.root_module.addImport("kafka", kafkazig);
    exe.linkSystemLibrary("rdkafka");

    b.installArtifact(exe);

    // ---- `zig build run` ----
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the kafka executable");
    run_step.dependOn(&run_cmd.step);

    // ---- Unit tests ----
    const exe_unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/kafka.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    _ = b.addRunArtifact(exe_unit_tests);
}
