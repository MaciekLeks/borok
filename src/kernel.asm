bits 64 ;from now on we use 32bits code, we cannot enter BIOS interrupts anymore (we need to write disk driver on our own ;))
section .kernel
global _start ;entry point for linker
global _mystart ;entry point for linker
extern kernel_main

; see boot.asm where this constant is defined using offsets
CODE_SELECTOR equ 0x08 ;code segment
DATA_SELECTOR equ 0x10 ;data segment

_start:
    mov ax, DATA_SELECTOR ;load data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov rbp, 0x00200000 ;stack pointer - 0x0020 * 0x04 = 0x00200000
    mov rsp, rbp ;stack pointer - 0x0020 * 0x04 = 0x00200000

    ; Enable A20 line
    ;in al, 0x92
    ;or al, 2
    ;out 0x92, al



    ; Enable interrupts - it could be to early (before IDT is set up) - TODO
    ;sti - oved to kernel_main, cause it's not safe to enable interrupts before IDT is set up

    call kernel_main ;call kernel_main function

    jmp $ ;jump to the current address - infinite loop



times 512-($-$$) db 0 ;fill the rest of the sector with 0s