# Basics of Dumb Language

This guide covers the foundational syntax (the core 30%) needed to write and structure your first `.dumb` program.

## 1. Architecture Mode

Every Dumb Language file begins by specifying the target CPU execution mode:

```dumb
bits 16     // 16-bit Real Mode (BIOS / Bootloaders)
bits 32     // 32-bit Protected Mode (Kernels / Linux / Windows)
```

## 2. Comments

Single-line comments use double slashes (`//`):

```dumb
// This is a comment
bits 32     // Inline comment
```

## 3. Data Types, Variables, and Buffers

Dumb Language supports integer values, string pointers, and fixed-size memory buffers (allocated in `.bss`).

```dumb
int counter = 0;                // 32-bit integer (.data)
char *msg = "Hello, World!\n";  // Null-terminated string pointer (.rodata)
char *buffer[32];               // 32-byte uninitialized buffer (.bss)
```

## 4. Functions and Entry Point

Functions are declared using C-style return types (`void`, `int`) and parameters. Execution starts at the top-level function call (commonly `Main()` or `kernel_main()`).

```dumb
void greet() {
    // Function body
}

int add_one(int x) {
    add x, 1;
    return x;
}

void Main() {
    greet();
    int result = add_one(5);
}

Main();     // Program entry point
```

## 5. Basic Arithmetic

Modify variables or registers directly using `add` and `sub`:

```dumb
int len = 10;
add len, 5;     // len is now 15
sub len, 1;     // len is now 14
```
