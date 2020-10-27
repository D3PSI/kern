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

void clear(void) {
    for(int i = 0; i < COLS * ROWS * BYTES_PER_CELL; i++) {
        term_buf[i] = ' ';
    }
}

void println(const char* _str, unsigned char _color) {
    static int index = 0;
    for(int i = 0; _str[i]; i++) {
        term_buf[index] = (unsigned short)_str[i] | (unsigned short)_color << 8;
        index++;
    }
    index += COLS - (index % COLS);
}

int main(void) {
    term_buf = (unsigned short*)VGA_ADDRESS;
    clear();
    println("This just fucking worked, damn", RED);
    println("Bye", GREEN);
    for(;;) {
        println("still running", WHITE);
    }
    return 0;
}
