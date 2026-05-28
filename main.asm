#include "nc16_assemble.asm"

main:
    mov c,func
    mov a,0xffff
    mul a,0x4
    jc c
    mov b,0x000a
    out b
    hlt

func:
    mov b,0xffff
    out b
    hlt