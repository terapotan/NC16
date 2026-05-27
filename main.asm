#include "nc16_assemble.asm"

in a
mov c,func1
cmp a,0x3
je c
mov b,0x000a
out b
hlt


func1:
    mov b,0xffff
    out b
    hlt