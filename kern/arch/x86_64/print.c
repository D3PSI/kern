#include "print.h"

const static size_t NUM_COLS = 80;
const static size_t NUM_ROWS = 25;

struct Char {
    uint8_t m_char;
    uint8_t m_color;
};

struct Char* s_buf = (struct Char*)0xb8000;
size_t s_col = 0;
size_t s_row = 0;
uint8_t s_color = PRINT_COLOR_WHITE | PRINT_COLOR_BLACK << 4;

void clear_row(size_t _row) {
    struct Char empty = (struct Char){
        m_char : ' ',
        m_color : s_color,
    };
    for (size_t col = 0; col < NUM_COLS; col++) {
        s_buf[col + NUM_COLS * _row] = empty;
    }
}

void print_clear() {
    for (size_t i = 0; i < NUM_ROWS; i++) {
        clear_row(i);
    }
}

void print_newline() {
    s_col = 0;
    if (s_row < NUM_ROWS - 1) {
        s_row++;
        return;
    }
    for (size_t row = 1; row < NUM_ROWS; row++) {
        for (size_t col = 0; col < NUM_COLS; col++) {
            struct Char character = s_buf[col + NUM_COLS * row];
            s_buf[col + NUM_COLS * (row - 1)] = character;
        }
    }
    clear_row(NUM_COLS - 1);
}

void print_char(char _char) {
    if (_char == '\n') {
        print_newline();
        return;
    }
    if (s_col > NUM_COLS) {
        print_newline();
    }
    s_buf[s_col + NUM_COLS * s_row] = (struct Char){
        m_char : (uint8_t)_char,
        m_color : s_color,
    };
    s_col++;
}

void print_str(char* _str) {
    for (size_t i = 0; 1; i++) {
        char character = (uint8_t)_str[i];
        if (character == '\0') {
            return;
        }
        print_char(character);
    }
}

void print_set_color(uint8_t _fg, uint8_t _bg) { s_color = _fg + (_bg << 4); }
