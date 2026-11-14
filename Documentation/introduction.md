# Introduction to Dumb Language

**Dumb Language** is a low-level, hybrid systems programming language that combines C-like high-level structure (functions, control flow, typed variables) with direct x86 Assembly control (registers, interrupts, stack operations, and raw memory layout).

It is designed for developers building **bootloaders, kernels, bare-metal firmware, and zero-dependency native executables** on Linux and Windows without runtime bloat.

## Core Philosophy

* **No Hidden Magic:** You control the CPU mode (`bits 16`, `bits 32`), memory origin (`org`), and system calls (`int 80h` or Win32 APIs) directly.
* **Readable Low-Level Code:** Write structured `if/else`, `while` loops, and functions alongside raw instructions like `move`, `push`, `pop`, and `call`.
* **Direct Hardware & OS Access:** Built-in support for standard GNU `linker.ld` scripts to compile multiple `.dumb` source files into flat binaries (`.img`, `.bin`) or native executables (ELF / PE).

## Documentation Roadmap

1. **[Basics (`basics.md`)](basics.md):** Architecture modes, variables, buffers, functions, and basic operators.
2. **[Core Teachings (`teachings.md`)](teachings.md):** Registers, stack manipulation, control flow, syscalls (Linux & Windows), and bare-metal directives.
3. **[Linker Guide (`linker.md`)](linker.md):** Using standard `linker.ld` scripts to organize memory sections and build multi-file projects.
