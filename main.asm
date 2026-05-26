#include "nc16_assemble.asm"


mov a,func1
jmp a

mov c,0x0000
out c
hlt

func1:
    mov c,0xffff
    out c
    hlt
