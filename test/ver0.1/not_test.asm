#include "nc16_assemble.asm"

mov a,1
mov b,2
mov c,3
mov d,4
mov e,5
mov bp,6
mov sp,7

not a
not a
out a

not b
not b
out b

not c
not c
out c

not d
not d
out d

not e
not e
out e

not bp
not bp
out bp

not sp
not sp
out sp

hlt