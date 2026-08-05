#include "nc16_assemble_USERPROGRAM.asm"

mov a,0xffff
setoutaddr 1
out a
mov a,0
;hlt
syscall
setoutaddr 1
out 0xff00
userret