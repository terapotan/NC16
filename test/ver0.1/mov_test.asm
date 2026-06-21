#include "nc16_assemble.asm"

mov a,1
mov b,a
mov c,b
mov d,c
mov e,d
mov bp,e
mov sp,bp

add sp,4
mov bp,sp
mov e,bp
mov d,e
mov c,d
mov b,c
mov a,b

out a
hlt