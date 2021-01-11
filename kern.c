#define VGA_BUF_ADDR 0x000B8000
#define VGA_BUF_COLS 80
#define VGA_BUF_ROWS 25

#define VGA_BLACK 0
#define VGA_GREEN 2
#define VGA_RED 4
#define VGA_YELLOW 14
#define VGA_WHITE 15

unsigned short* vga_buf;

void init_vga_buf() { vga_buf = (unsigned short*)VGA_BUF_ADDR; }

void clear(void) {
    for (int i = 0; i < VGA_BUF_COLS * VGA_BUF_ROWS; i++) {
        vga_buf[i] = ' ';
    }
}

void println(const char* _str, unsigned char _color) {
    static int index = 0;
    for (int i = 0; _str[i]; i++) {
        vga_buf[index] = (unsigned short)_str[i] | (unsigned short)_color << 8;
        index++;
    }
    index += VGA_BUF_COLS - (index % VGA_BUF_COLS);
}

int main(void) {
    init_vga_buf();
    clear();
    println("This just fucking worked, damn", VGA_RED);
    println("Bye", VGA_GREEN);
    return 0;
}
