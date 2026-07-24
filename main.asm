#include "nc16_assemble.asm"

interrupt_handler_base_address = 0x5000
interrupt_number_1 = 1

mov memaddr,0x0000
; 割り込みハンドラを設定
num1 = interrupt_handler_base_address+interrupt_number_1
mov memval,int_handler
mov [memaddr+num1],memval

mov a,0
loop:
    add a,1
    setoutaddr 0x1
    out a
    jmp loop

int_handler:
    setinaddr 0x0
    setoutaddr 0x0
    in b
    out b
    setoutaddr 0x1
    intret