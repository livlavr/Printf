#include <stdio.h>
#include <limits.h>

extern "C" int print(const char*, ...);

int main() {
// Test 0
    print("Unsigned: %u, Octal: %o, HEX: %x\n", 255, 255, 255);
    printf("Unsigned: %u, Octal: %o, HEX: %x\n\n", 255, 255, 255);

// Test 1
    int x;
    print("Ptr: %x string: %s\n", &x, "MIPT!");
    printf("Ptr: %x string: %s\n\n", &x, "MIPT!");

// Test 2
    print("%c %s 0x%x %d%%%c %u\n", 'I', "♥", 255, 100, '!', 1234567890);
    printf("%c %s 0x%x %d%%%c %u\n\n", 'I', "♥", 255, 100, '!', 1234567890);

// Test 3
    print("%d %d %u %u\n", INT_MAX, INT_MIN, 0, 1234567890);
    printf("%d %d %u %u\n", INT_MAX, INT_MIN, 0, 1234567890);
}