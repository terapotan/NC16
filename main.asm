#include "nc16_assemble.asm"
in a
mov b,0x0000
main:
    mov [a],b
    add a,1
    mov [a],b
    add b,0x0001
    mov c,[a]
    in a
    out c
    jmp main
hlt