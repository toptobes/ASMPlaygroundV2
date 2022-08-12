#include <windows.h>

/* Allows windows command prompt to parse and use ansi escape sequences */
extern "C" void ansi_support() {
    HANDLE hInput = GetStdHandle(STD_INPUT_HANDLE), hOutput = GetStdHandle(STD_OUTPUT_HANDLE); // Does something
    DWORD dwMode; // Does something else

    GetConsoleMode(hOutput, &dwMode); // Does the penultimate thing
    dwMode |= ENABLE_PROCESSED_OUTPUT | ENABLE_VIRTUAL_TERMINAL_PROCESSING; // Does the last thing
}