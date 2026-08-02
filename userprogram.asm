#include "nc16_assemble_USERPROGRAM.asm"

mov a,0xffff
setoutaddr 1
out a
hlt
userret