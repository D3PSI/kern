const builtin = @import("builtin");

const Multiboot2 = packed struct {
    magic: u32,
    arch: i32,
    header_length: i32,
    checksum: i32,
    end_tag: i64,
};

const MAGIC = 0xe85250d6; // multiboot2
const ARCH = 0x0; // protected mode i386
const HEADER_LENGTH = @sizeOf(Multiboot2);
const CHECKSUM = 0x100000000 - (MAGIC + HEADER_LENGTH);
const END_TAG = 0x8;

export var multiboot align(4) linksection(".multiboot2") = Multiboot2{
    .magic = MAGIC,
    .arch = ARCH,
    .header_length = HEADER_LENGTH,
    .checksum = CHECKSUM,
    .end_tag = END_TAG,
};

export var page_table_l4: [4 * 1024]u8 align(8) linksection(".bss") = undefined;
export var page_table_l3: [4 * 1024]u8 align(8) linksection(".bss") = undefined;
export var page_table_l2: [4 * 1024]u8 align(8) linksection(".bss") = undefined;
export var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;
const stack_bytes_slice = stack_bytes[0..];

export fn kern_start() callconv(.Naked) noreturn {
    @call(.{ .stack = stack_bytes_slice }, kern_init, .{});
    unreachable;
}

fn check_multiboot() usize {
    return asm volatile (
        \\ cmp 0x36d76289, %%eax
        \\ jne .no_multiboot
        \\ mov 1, %[ret]
        \\ ret
        \\ .no_multiboot:
        \\ mov 0, %[ret]
        \\ ret
        : [ret] "=r" (-> usize)
        :
        : "%eax"
    );
}

fn check_cpuid() usize {
    return asm volatile (
        \\ pushfd
        \\ pop %%eax
        \\ mov %%eax, %%ecx
        \\ xor 1 << 21, %%eax
        \\ push %%eax
        \\ popfd
        \\ pushfd
        \\ pop %%eax
        \\ push %%ecx
        \\ popfd
        \\ cmp %%ecx, %%eax
        \\ je .no_cpuid
        \\ mov 1, %[ret]
        \\ ret
        \\ .no_cpuid:
        \\ mov 0, %[ret]
        \\ ret
        : [ret] "=r" (-> usize)
        :
        : "%eax", "%ecx"
    );
}

fn check_long_mode() usize {
    return asm volatile (
        \\ mov 0x80000000, %%eax
        \\ cpuid
        \\ cmp 0x80000001, %%eax
        \\ jb .no_long_mode
        \\ mov 0x80000001, %%eax
        \\ cpuid
        \\ test 1 << 29, %%edx
        \\ jz .no_long_mode
        \\ mov 1, %[ret]
        \\ ret
        \\ .no_long_mode:
        \\ mov 0, %[ret]
        \\ ret
        : [ret] "=r" (-> usize)
        :
        : "%eax", "%edx"
    );
}

fn setup_page_tables() void {
    asm volatile (
        \\ mov page_table_l3, %%eax
        \\ or 0b11, %%eax
        \\ mov %%eax, [page_table_l4]
        \\ mov page_table_l2, %%eax
        \\ or 0b11, %%eax
        \\ mov %%eax, [page_table_l3]
        \\ mov 0, %%ecx
        \\ .loop:
        \\ mov 0x200000, %%eax
        \\ mul %%ecx
        \\ or 0b10000011, %%eax
        \\ mov %%eax, page_table_l2(,%%ecx, 8)
        \\ inc %%ecx
        \\ cmp 512, %%ecx
        \\ jne .loop
        \\ ret
        ::: "%eax", "%ecx");
}

fn enable_paging() void {
    asm volatile (
        \\ mov page_table_l4, %%eax
        \\ mov %%eax, %%cr3
        \\ mov %%cr4, %%eax
        \\ or 1 << 5, %%eax
        \\ mov %%eax, %%cr4
        \\ mov 0xC0000080, %%ecx
        \\ rdmsr
        \\ or 1 << 8, %%eax
        \\ wrmsr
        \\ mov %%cr0, %%eax
        \\ or 1 << 31, %%eax
        \\ mov %%eax, %%cr0
        \\ ret
        ::: "%eax", "%cr3", "%cr4", "%ecx", "%cr0");
}

fn clear_data_segment_registers() void {
    asm volatile (
        \\ mov 0, %%ax
        \\ mov %%ax, %%ss
        \\ mov %%ax, %%ds
        \\ mov %%ax, %%es
        \\ mov %%ax, %%fs
        \\ mov %%ax, %%gs
        ::: "%ax", "%ss", "%ds", "%es", "%fs", "%gs");
}

fn kern_init() void {
    if (check_multiboot() != 1) {
        // TODO: throw an error
    }
    if (check_cpuid() != 1) {
        // TODO: throw an error
    }
    if (check_long_mode() != 1) {
        // TODO: throw an error
    }
    setup_page_tables();
    enable_paging();
    clear_data_segment_registers();
    kern_main();
    unreachable;
}

pub fn panic(msg: []const u8, error_return_trace: ?*builtin.StackTrace) noreturn {
    @setCold(true);
    terminal.write("KERNEL PANIC: ");
    terminal.write(msg);
    unreachable;
}

fn kern_main() void {
    terminal.initialize();
    terminal.write("Hello, Kernel World from Zig 0.6.0!");
}

// Hardware text mode color constants
const VgaColor = u8;
const VGA_COLOR_BLACK = 0;
const VGA_COLOR_BLUE = 1;
const VGA_COLOR_GREEN = 2;
const VGA_COLOR_CYAN = 3;
const VGA_COLOR_RED = 4;
const VGA_COLOR_MAGENTA = 5;
const VGA_COLOR_BROWN = 6;
const VGA_COLOR_LIGHT_GREY = 7;
const VGA_COLOR_DARK_GREY = 8;
const VGA_COLOR_LIGHT_BLUE = 9;
const VGA_COLOR_LIGHT_GREEN = 10;
const VGA_COLOR_LIGHT_CYAN = 11;
const VGA_COLOR_LIGHT_RED = 12;
const VGA_COLOR_LIGHT_MAGENTA = 13;
const VGA_COLOR_LIGHT_BROWN = 14;
const VGA_COLOR_WHITE = 15;

fn vga_entry_color(fg: VgaColor, bg: VgaColor) u8 {
    return fg | (bg << 4);
}

fn vga_entry(uc: u8, color: u8) u16 {
    var c: u16 = color;
    return uc | (c << 8);
}

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;

const terminal = struct {
    var row: usize = 0;
    var column: usize = 0;
    var color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
    const buffer = @intToPtr([*]volatile u16, 0xB8000);
    fn initialize() void {
        var y: usize = 0;
        while (y < VGA_HEIGHT) : (y += 1) {
            var x: usize = 0;
            while (x < VGA_WIDTH) : (x += 1) {
                putCharAt(' ', color, x, y);
            }
        }
    }

    fn setColor(new_color: u8) void {
        color = new_color;
    }

    fn putCharAt(c: u8, new_color: u8, x: usize, y: usize) void {
        const index = y * VGA_WIDTH + x;
        buffer[index] = vga_entry(c, new_color);
    }

    fn putChar(c: u8) void {
        putCharAt(c, color, column, row);
        column += 1;
        if (column == VGA_WIDTH) {
            column = 0;
            row += 1;
            if (row == VGA_HEIGHT)
                row = 0;
        }
    }

    fn write(data: []const u8) void {
        for (data) |c|
            putChar(c);
    }
};
