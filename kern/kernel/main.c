#include "print.h"

void kern_main(void) {
    print_clear();
    print_set_color(PRINT_COLOR_YELLOW, PRINT_COLOR_BLACK);
    print_str("Upgrading the kernel to 64-bit is literally easy, lol");
}
