const std = @import("std");
const builtin = @import("builtin");
const is_test = builtin.is_test;

comptime {
    if (!is_test) {
        switch (std.Target.current.cpu.arch) {
            .i386 => _ = @import("arch/x86_64/boot/main.zig"),
            else => unreachable,
        }
    }
}

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}
