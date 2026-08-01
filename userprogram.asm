#include "nc16_assemble_USERPROGRAM.asm"

loop:
    mov a,0
    setoutaddr 1
    out a
    add a,1
    jmp loop