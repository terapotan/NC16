#include "nc16_assemble_USERPROGRAM.asm"

mov a,0
loop:
    setoutaddr 1
    out a
    add a,1
    jmp loop