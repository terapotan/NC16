#include "nc16_assemble.asm"

interrupt_handler_base_address = 0x5000
interrupt_number = 1
mov memaddr,0x0000
; 割り込みハンドラを設定
num = interrupt_handler_base_address+interrupt_number
mov memval,int_handler
mov [memaddr+num],memval

in a
loop:
    out a
    add a,1
    jmp loop

int_handler:
    out 0xffff
    hlt