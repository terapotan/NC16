#include "nc16_assemble.asm"

in a
main:
    cmp a,0x0005
    jz suc
    mov a,0xff00
    out a
    hlt

suc:
    mov a,0xffff
    out a
    hlt