#include "nc16_assemble.asm"

push 0xffff
mov b,0x10
push b
pop a
out a
nop
pop a
out a
hlt