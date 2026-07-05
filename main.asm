#include "nc16_assemble.asm"

mov a,0x25
mov b,0x20
cmp a,b
nop
nop
nop
nop
jl stop
hlt

stop:
out 0xffff
hlt