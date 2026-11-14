# Core Teachings: Systems & Low-Level Programming

This guide covers the core 70% of **Dumb Language**, detailing register architecture, memory addressing, stack frames, control flow, OS system calls, Win32 ABI conventions, and bare-metal hardware directives.

---

## 1. x86 Register Architecture & `move`

Dumb Language exposes general-purpose, index, and stack pointer registers directly. Values are transferred using `move`, supporting decimal, hexadecimal (`h` suffix), and memory labels.

### Available Registers (32-bit Mode)

| Register | Role & Conventional Usage |
| :--- | :--- |
| `eax` | Accumulator — arithmetic results, syscall numbers, function return values |
| `ebx` | Base — base pointer for memory access, first syscall argument |
| `ecx` | Counter — loop counters, second syscall argument |
| `edx` | Data — I/O port addresses, third syscall argument |
| `esi` | Source Index — string/array iteration index and source pointers |
| `edi` | Destination Index — destination buffer pointers and saved lengths |
| `esp` | Stack Pointer — points to the current top of the hardware stack |
| `ebp` | Base Pointer — anchors the current function stack frame |

```dumb
move eax = 4h;              // Immediate hexadecimal value (0x04)
move ebx = 1;               // Immediate decimal value
move ecx = buffer;          // Memory address of global label 'buffer'
move edi = eax;             // Register-to-register transfer
```

---

## 2. Memory Addressing & Buffers

Global variables are placed into distinct memory sections depending on initialization:
* **Initialized pointers/strings (`.rodata` / `.data`):** Store literal bytes in the binary.
* **Sized buffers (`.bss`):** Reserve zero-initialized RAM without increasing binary file size.

```dumb
char *header = "DUMB_OS\n";      // Stored in .rodata (9 bytes including '\0')
int status   = 1;                // Stored in .data (4 bytes)
char *rx_buf;                // Reserved in .bss (64 bytes, 0 bytes on disk)
```

### Direct Memory & Indexed Access

Access individual bytes inside a buffer using bracket indexing (`buffer[index]`), or write directly to physical memory addresses (such as VGA text memory at `0xB8000`):

```dumb
// Byte-level buffer inspection
move esi = 0;
if (rx_buf[esi] == 41h) {        // Check if first byte is ASCII 'A' (0x41)
    move status = 2;
}

// Direct physical memory write (32-bit Protected Mode VGA buffer)
move [B8000h] = 0F4Fh;           // Write white 'O' on black background
move [B8002h] = 0F4Bh;           // Write white 'K' on black background
```

---

## 3. Control Flow & Comparisons

Dumb Language provides structured `if / else` branches and `while` loops that compile directly into conditional jump instructions (`cmp`, `je`, `jne`, `jl`, `jmp`).

### Supported Comparison Operators

* `==` (Equal)
* `!=` (Not equal)
* `<` (Less than)
* `>` (Greater than)
* `<=` (Less than or equal)
* `>=` (Greater than or equal)

```dumb
int compare_buffers(char *a, char *b, int len) {
    move esi = 0;

    while (esi < len) {
        if (a[esi] != b[esi]) {
            return 0;            // Mismatch found: early exit
        }
        add esi, 1;
    }

    return 1;                    // All bytes matched
}
```

---

## 4. Hardware Stack & Calling Conventions

Use `push`, `pop`, and `call` to manipulate the x86 stack directly.

### Stack Allocation Trick (`push 0` + `push esp`)

When an external API requires a pointer to a temporary 32-bit output variable (such as `WriteConsoleA` or `ReadConsoleA`), you can allocate space directly on the stack without declaring a global variable:

```dumb
push 0;             // Reserve 4 zeroed bytes on the stack
push esp;           // Pass the address of those 4 bytes as an output pointer
call SomeWin32API;  // API writes result into the reserved stack slot
pop eax;            // Retrieve the written value into EAX and restore ESP
```

---

## 5. Linux 32-bit System Call Interface (`int 80h`)

On Linux x86, software interrupt `80h` transitions from user space to kernel space.

| Syscall | `eax` | `ebx` | `ecx` | `edx` | Return (`eax`) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `sys_exit` | `1h` | Exit code | — | — | Does not return |
| `sys_read` | `3h` | File descriptor (`0` = stdin) | Buffer pointer | Max bytes | Bytes read |
| `sys_write` | `4h` | File descriptor (`1` = stdout) | String pointer | Byte length | Bytes written |

```dumb
int read_line(char *dst, int max_len) {
    move eax = 3h;              // sys_read
    move ebx = 0h;              // stdin
    move ecx = dst;
    move edx = max_len;
    int 80h;
    sub eax, 1;                 // Strip trailing '\n' (1 byte on Linux)
    return eax;
}
```

---

## 6. Windows 32-bit Native ABI (`extern` & `stdcall`)

On Windows, external symbols from `kernel32.dll` or `user32.dll` are declared with `extern`. The Win32 API uses the **`stdcall` calling convention**:
1. Arguments are pushed onto the stack from **right to left**.
2. The called Windows function cleans up the stack before returning.
3. Return values are placed in `eax`.

```dumb
extern GetStdHandle;
extern WriteConsoleA;
extern ExitProcess;

void write_console(char *msg, int len) {
    push -11;                   // STD_OUTPUT_HANDLE (-11)
    call GetStdHandle;          // Handle returned in EAX

    push 0;                     // lpReserved (NULL)
    push esp;                   // lpNumberOfCharsWritten (dummy pointer)
    push len;                   // nNumberOfCharsToWrite
    push msg;                   // lpBuffer
    push eax;                   // hConsoleOutput
    call WriteConsoleA;
}
```

> **Line Endings Note:** Windows console input terminates lines with `\r\n` (2 bytes), whereas Linux uses `\n` (1 byte). Always subtract `2` when stripping newlines from `ReadConsoleA` buffers.

---

## 7. Bare-Metal & Bootloader Directives

When targeting raw hardware without an OS, Dumb Language provides binary layout primitives:

* **`org <addr>`:** Sets the base memory offset for label address calculations (e.g., `org 7c00h` for BIOS boot sectors).
* **`db`, `dw`, `dd`:** Emits raw 8-bit, 16-bit, or 32-bit values directly into the binary stream.
* **`pad (<expr>) db <val>`:** Fills bytes up to a calculated offset (using `$` for current address and `$$` for section start).

### Example A: 16-bit BIOS Master Boot Record (512 bytes)

```dumb
bits 16
org 7c00h

void boot_entry() {
    while (1) {}
}

boot_entry();

pad (510 - (\(-\))) db 0;      // Pad binary to exact byte 510
dw AA55h;                       // Little-endian boot signature (0x55, 0xAA)
```

### Example B: 32-bit Multiboot Header (GRUB / QEMU)

```dumb
bits 32

dd 1BADB002h;                   // Multiboot magic number
dd 00h;                         // Boot flags
dd -(1BADB002h + 00h);          // Checksum (must sum to 0)

void kernel_main() {
    while (1) {}
}

kernel_main();
```
