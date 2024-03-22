const std = @import("std");
const builtin = @import("builtin");
const Build = @import("std").Build;
const Target = @import("std").Target;
const CrossTarget = @import("std").zig.CrossTarget;
const Feature = @import("std").Target.Cpu.Feature;

fn nasmRun(b: *Build, src: []const u8, dst: []const u8, options: []const []const u8, prev_step: ?*std.Build.Step) error{OutOfMemory}!*std.Build.Step {
    var args = std.ArrayList([]const u8).init(b.allocator);
    try args.append("nasm");
    try args.append(src);
    try args.append("-o");
    try args.append(dst);
    for (options) |option| {
        try args.append(option);
    }

    const cmd = b.addSystemCommand(args.items);
    cmd.step.name = src;
    if (prev_step) |step| {
        cmd.step.dependOn(step);
    }
    return &cmd.step;
}

fn resolveTarget(b: *Build, arch: Target.Cpu.Arch) !Build.ResolvedTarget {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = arch,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_features_add = switch (arch) {
            .x86_64 => blk: {
                var features = Feature.Set.empty;
                features.addFeature(@intFromEnum(Target.x86.Feature.soft_float));
                break :blk features;
                },
            else => return error.UnsupportedArch,
        },
        .cpu_features_sub = switch (arch) {
            .x86_64 => blk: {
                var features = Feature.Set.empty;
                features.addFeature(@intFromEnum(Target.x86.Feature.mmx));
                features.addFeature(@intFromEnum(Target.x86.Feature.sse));
                features.addFeature(@intFromEnum(Target.x86.Feature.sse2));
                features.addFeature(@intFromEnum(Target.x86.Feature.avx));
                features.addFeature(@intFromEnum(Target.x86.Feature.avx2));
                break :blk features;
                },
            else => return error.UnsupportedArch,
        },
    });
    return target;
}

pub fn build(b: *Build) !void {
    b.enable_qemu = true;

    const target = try resolveTarget(b, .x86_64);

    var last_step_ptr = nasmRun(b, "src/boot/boot.asm", "zig-out/bin/boot.bin", &[_][]const u8{ "-f", "bin" }, null) catch unreachable;
    last_step_ptr = nasmRun(b, "src/boot/extended_boot.asm", "zig-out/bin/extended_boot.bin", &[_][]const u8{ "-f", "bin" }, last_step_ptr) catch unreachable;
    last_step_ptr = nasmRun(b, "src/kernel.asm", "zig-out/bin/kernel.asm.o", &[_][]const u8{ "-f", "elf64", "-g" }, last_step_ptr) catch unreachable;


    const optimize = b.standardOptimizeOption(.{
        //.preferred_optimize_mode = .Debug,
        .preferred_optimize_mode = .ReleaseSafe,
    });

    const kernel_elf = b.addExecutable(.{
        .name = "kernel.elf",
        .root_source_file = .{ .path = "src/kernel.zig" },
        .target = target,
        .optimize = optimize,
        .single_threaded = true,
        .code_model = .kernel,
        .pic = false, //TODO: check if this is needed
    });
    kernel_elf.addObjectFile(std.Build.LazyPath{
        .path = "zig-out/bin/kernel.asm.o",
    });
    kernel_elf.setLinkerScript(std.Build.LazyPath{
        .path = "linker.ld",
    });
    kernel_elf.out_filename = "kernel.elf";
    kernel_elf.pie = false;
    kernel_elf.step.dependOn(last_step_ptr);

    b.installArtifact(kernel_elf);
    //b.default_step.dependOn(&install_elf.step);
    //b.getInstallStep().dependOn(&install_elf.step);

    //const obj_copy = b.addSystemCommand(&[_][]const u8{ "objcopy", "-O", "binary", "-S", "zig-out/bin/kernel.elf", "zig-out/bin/kernel.bin" });
    // const obj_copy = b.addSystemCommand(&[_][]const u8{ "objcopy"});
    // obj_copy.addArgs(&[_][]const u8{"-O", "binary", "-S"});
    // obj_copy.addArtifactArg(kernel_elf);
    // const prefix = b.install_prefix;
    // _ = obj_copy.addPrefixedOutputFileArg(prefix, "kernel.bin");
    // obj_copy.step.name = "elf to binary file";
    // obj_copy.step.dependOn(&kernel_elf.step);

    // src: https://stackoverflow.com/questions/77074657/how-to-objcopy-a-bin-file-as-part-of-a-zig-build-script
    const bin = b.addObjCopy(kernel_elf.getEmittedBin(), .{
        .format = .bin,
    });
    bin.step.dependOn(&kernel_elf.step);
    const copy_bin = b.addInstallBinFile(bin.getOutput(), "kernel.bin");
    // const bin = b.addObjCopy(kernel_elf.getEmittedBin(), .{
    //     .format = .bin,
    // });
    // bin.step.dependOn(&kernel_elf.step);

    // Copy the bin to the output directory
    //const ins_bin = b.addInstallBinFile(bin.getOutput(), "kernel.bin");
    //b.default_step.dependOn(&ins_bin.step);

    // const bootBin = b.addSystemCommand(&[_][]const u8{ "dd", "if=zig-out/bin/boot.bin", "of=zig-out/bin/os.bin" });
    // bootBin.step.name = "dd boot.bin";
    // bootBin.step.dependOn(&copy_bin.step);

    const os_bin = b.addSystemCommand(&[_][]const u8{"dd"});
    ///////////////os_bin.addPrefixedFileArg("if=", boot_bin_path2);
    os_bin.addArg("if=zig-out/bin/boot.bin");
    os_bin.addArg("of=zig-out/bin/os.bin");
    os_bin.step.name = "dd boot.bin";
    os_bin.step.dependOn(&copy_bin.step);

    const os_bin2 = b.addSystemCommand(&[_][]const u8{"dd"});
    os_bin2.addArg("if=zig-out/bin/extended_boot.bin");
    os_bin2.addArg("of=zig-out/bin/os.bin");
    os_bin2.addArgs(&[_][]const u8{ "seek=1", "bs=512", "conv=sync" });
    os_bin2.step.name = "dd extended_boot.bin";
    os_bin2.step.dependOn(&os_bin.step);

    const kernelBin = b.addSystemCommand(&[_][]const u8{ "dd", "if=zig-out/bin/kernel.bin", "of=zig-out/bin/os.bin", "seek=2", "bs=512", "conv=sync" });
    kernelBin.step.name = "dd kernel.bin";
    //kernelBin.step.dependOn(&bootBin.step);
    kernelBin.step.dependOn(&os_bin2.step);

    const padding = b.addSystemCommand(&[_][]const u8{ "dd", "if=/dev/zero", "of=zig-out/bin/os.bin", "bs=512", "count=5000", "conv=notrunc", "oflag=append" });
    padding.step.name = "dd padding";
    padding.step.dependOn(&kernelBin.step);

    var ddStep = b.step("dd", "Run dd commands");
    //ddStep.dependOn(&bootBin.step);
    /////////////////ddStep.dependOn(&ins_boot_bin.step);
    ddStep.dependOn(&os_bin.step);
    ddStep.dependOn(&kernelBin.step);
    ddStep.dependOn(&padding.step);

    // b.default_step.dependOn(ddStep);
    b.getInstallStep().dependOn(ddStep);
}
