
//const builtin = @import("builtin");
const pty = @import("terminal/console.zig");
const mm = @import("memory/mmap.zig");
const Heap = @import("memory/heap/heap.zig").Heap;
const com = @import("common/common.zig");
//export means that linker can see this function

var str = "\n- long-mode, \n- paging for 2MB, \n- sys memory map.";
pub export fn kernel_main()  void  {
    // const color_ptr = &term.color;
    // color_ptr.* = 0x0f;
    pty.initialize(pty.ConsoleColors.Cyan, pty.ConsoleColors.DarkGray);
    pty.puts("I'm real Borok OS\n");
    pty.printf("My message to you: {s}", .{str});

    // Get system momory map and check if some address is availiable to use
    const smap =  mm.SysMemMap.init();
    const v_addr = 0x100_0000;
    const v_len = 0x1000;
    const is_free = smap.isFree(v_addr, v_len);
    if (is_free) {
        pty.puts("\n0x100_0000 mem is free!\n");
    } else {
        pty.puts("\n0x100_0000 mem is not free!\n");
    }

    //only 4KB - not finished
    const heap = Heap.init(com.OS_HEAP_ADDRESS ,com.OS_HEAP_TABLE_ADDRESS, 0x100) catch  {
        pty.puts("Heap init error\n");
        return;
    };
    _ = heap;
}
