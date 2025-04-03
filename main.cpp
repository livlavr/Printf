#include <stdio.h>

extern "C" int print(const char*);

int main() {
    int ret = print("lasdkjf%ulskdfj\n");
}