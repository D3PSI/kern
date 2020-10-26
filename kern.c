// video memory buffer start address
#define VGA_ADDRESS 0xB8000

// VGA supports 16 colors
#define BLACK 0
#define GREEN 2
#define RED 4
#define YELLOW 14
#define WHITE 15

// video buffer dimensions 
#define COLS 80
#define ROWS 25
#define BYTES_PER_CELL 2

unsigned short* term_buf;
unsigned int vga_index;

void clear_screen(void) {
    int index = 0;
    while(index < COLS * ROWS * BYTES_PER_CELL) {
        term_buf[index] = ' ';
        index += 2;
    }
}

void print_string(const char* _str, unsigned char _color) {
    int index = 0;
    while(_str[index]) {
        term_buf[vga_index] = (unsigned short)_str[index] | (unsigned short)_color << 8;
        index++;
        vga_index++;
    }
}

int main(void) {
    term_buf = (unsigned short*)VGA_ADDRESS;
    vga_index = 0;
    clear_screen();
    print_string("This just fucking worked, damn", RED);
    vga_index = 80;
    print_string("Bye", GREEN);
    return 0;
}
