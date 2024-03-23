# What is Borok
In the Silesian language, 'borok' means a loser, a victim of fate, or someone who is inept.
This is fitting for my first attempt to create an x64 OS in Zig.

# About Borok
- Borok is a basic version of an x64 OS, written in NASM and Zig.

# Features include:
- An MBR bootloader
- The ability to switch from real-mode to long-mode
- Displaying output on the screen
- Setting up the system memory map
- Managing paging for up to 2MB (only asm code)
- PIC initialization

# The Future
I've stopped working on this project and I'm not planning to continue it. I'm focusing on another x64 OS project that primarily uses Zig and the Limine bootloader.
So, look out for Bebok (in Silesian language, a creature from demonology).

# How to run
```bash
zig build
qemu-system-x86_64  -drive format=raw,file=zig-out/bin/os.bin
```