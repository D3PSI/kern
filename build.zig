const builtin = @import("builtin");
const std = @import("std");
const Builder = std.build.Builder;
const Step = std.build.Step;
const Target = std.Target;
const CrossTarget = std.zig.CrossTarget;
const fs = std.fs;
const File = fs.File;
const ArrayList = std.ArrayList;
const Mode = builtin.Mode;

const x86_i686 = CrossTarget{
    .cpu_arch = .i386,
    .os_tag = .freestanding,
    .cpu_model = .{ .explicit = &Target.x86.cpu._i686 },
};

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{ .whitelist = &[_]CrossTarget{x86_i686}, .default_target = x86_i686 });
    const arch = switch (target.getCpuArch()) {
        .i386 => "x86_64",
        else => unreachable,
    };

    const kernel_root = "kernel/main.zig";
    const arch_root = "kernel/arch";
    const target_root = "kernel/target";

    const linker_script_path = try fs.path.join(b.allocator, &[_][]const u8{ target_root, arch, "linker.ld" });
    const output_iso = try fs.path.join(b.allocator, &[_][]const u8{ b.install_path, "kern.iso" });
    const iso_dir_path = try fs.path.join(b.allocator, &[_][]const u8{ b.install_path, "iso" });
    const boot_path = try fs.path.join(b.allocator, &[_][]const u8{ b.install_path, "iso", "boot" });

    const build_mode = b.standardReleaseOptions();

    const kern = b.addExecutable("kern.elf", kernel_root);
    kern.setOutputDir(b.install_path);
    kern.setBuildMode(build_mode);
    kern.setLinkerScriptPath(linker_script_path);
    kern.setTarget(target);

    const iso = switch (target.getCpuArch()) {
        .i386 => b.addSystemCommand(&[_][]const u8{ "./scripts/iso.sh", boot_path, iso_dir_path, kern.getOutputPath(), output_iso }),
        else => unreachable,
    };
    iso.step.dependOn(&kern.step);

    b.default_step.dependOn(&iso.step);

    var qemu_args_al = ArrayList([]const u8).init(b.allocator);
    defer qemu_args_al.deinit();

    switch (target.getCpuArch()) {
        .i386 => try qemu_args_al.append("qemu-system-i386"),
        else => unreachable,
    }
    try qemu_args_al.append("-serial");
    try qemu_args_al.append("stdio");
    switch (target.getCpuArch()) {
        .i386 => {
            try qemu_args_al.append("-boot");
            try qemu_args_al.append("d");
            try qemu_args_al.append("-cdrom");
            try qemu_args_al.append(output_iso);
        },
        else => unreachable,
    }

    var qemu_args = qemu_args_al.toOwnedSlice();

    const run_step = b.step("run", "Run with qemu");
    const run_debug_step = b.step("debug-run", "Run with qemu and wait for a gdb connection");

    const qemu_cmd = b.addSystemCommand(qemu_args);
    const qemu_debug_cmd = b.addSystemCommand(qemu_args);
    qemu_debug_cmd.addArgs(&[_][]const u8{ "-s", "-S" });

    qemu_cmd.step.dependOn(&iso.step);
    qemu_debug_cmd.step.dependOn(&iso.step);

    run_step.dependOn(&qemu_cmd.step);
    run_debug_step.dependOn(&qemu_debug_cmd.step);

    const debug_step = b.step("debug", "Debug with gdb and connect to a running qemu instance");
    const symbol_file_arg = try std.mem.join(b.allocator, " ", &[_][]const u8{ "symbol-file", kern.getOutputPath() });
    const debug_cmd = b.addSystemCommand(&[_][]const u8{
        "gdb-multiarch",
        "-ex",
        symbol_file_arg,
        "-ex",
        "set architecture auto",
    });
    debug_cmd.addArgs(&[_][]const u8{
        "-ex",
        "target remote localhost:1234",
    });
    debug_step.dependOn(&debug_cmd.step);
}
