ENTRY(_start)
SECTIONS /* nasm will compile to elf first so we need sections */
{
    . = 1M; /* kernel (not boot loaded) is going to be loaded at 0x100000 = 2^20 = 1048576B = 1024kB*/

    .kernel :
    {
        *(.kernel)
    } :text :interp

   .rodata : ALIGN(4096)
   {
       *(.rodata)
   }
   .data : ALIGN(4096)
   {
    *(.data)
   }

   .bss : ALIGN(4096)
    {
        *(COMMON)
        *(.bss)
     }

    .text : ALIGN(4096) /*4kB page aligned */
    {
        *(.text) /*read as follows: all .text sections from all files put here */
    }

    /*.asm - section for the rest except kernel.asm asm objects */
    .asm : ALIGN(4096)
    {
        *(.asm)
    }
}
