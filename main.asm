#include "nc16_assemble.asm"

interrupt_handler_base_address = 0x5000
interrupt_number_1 = 1
interrupt_number_2 = 2

mov memaddr,0x0000
; 割り込みハンドラを設定
num1 = interrupt_handler_base_address+interrupt_number_1
num2 = interrupt_handler_base_address+interrupt_number_2
mov memval,int_handler
mov [memaddr+num1],memval

mov memval,int_handler_long
mov [memaddr+num2],memval

in a
loop:
    out a
    add a,1
    jmp loop

int_handler:
    out 0xffff
    out 0x0000
    out 0xffff
    intret

int_handler_long:
    out 0xffff
    out 0x0000
    out 0xffff
    out 0x0000
    out 0xffff
    out 0x0000
    out 0xffff
    out 0x0000
    out 0xffff
    out 0x0000
    out 0xffff
    out 0x0000
    out 0xffff
    out 0x00ff
    intret