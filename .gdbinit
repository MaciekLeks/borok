# reload
define mr
    source .gdbinit
end
set disassemble-next-line on
# we start at the .text section not .kernel in the elf file, see llvm-readelf -S zig-out/bin/kernel.el

#add-symbol-file zig-out/bin/kernel.elf 0x100240
# 280 - kernel_main
add-symbol-file zig-out/bin/kernel.elf 0x101f10
target remote | qemu-system-x86_64 -m 2024 -drive format=raw,file=zig-out/bin/os.bin -S -gdb stdio
set architecture i8086
#break *0x7c00
#break *0x7c4f
#break *0x7d47
break *0x7e00
# jump to 0x100000
break *0x7f29
#set architecture auto
#break *0x100590
## stop here and set architecture i386
#break *0x7c6a
## stop after call to ata_lba_read driver
##break *0x7c7e
break kernel_main
break 0x100bf1
#break 'memory.mmap.MemMap.init'
#break 'memory.mmap.MapMem.isFree'
#break 'memory.heap.heap.Heap.init'
breal 'memory.memory.memset'


