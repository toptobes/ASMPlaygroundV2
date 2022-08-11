#include <windows.h>

extern "C" void ansi_support() {
    HANDLE hInput = GetStdHandle(STD_INPUT_HANDLE), hOutput = GetStdHandle(STD_OUTPUT_HANDLE);
    DWORD dwMode;

    GetConsoleMode(hOutput, &dwMode);
    dwMode |= ENABLE_PROCESSED_OUTPUT | ENABLE_VIRTUAL_TERMINAL_PROCESSING;
}