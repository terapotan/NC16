#include "nc16_assemble.asm"
mov a,0xffff
mov b,0xffff
mov c,0xffff
mov d,0xffff
mov e,0xffff
mov bp,0xffff
mov sp,0x0000

and a, a
and a, b
and a, c
and a, d
and a, e
and a, bp
and a, sp

; expect 0
out a

mov a,0xffff
mov b,0xffff
mov c,0xffff
mov d,0xffff
mov e,0xffff
mov bp,0xffff
mov sp,0x0000

and b, b
and b, a
and b, c
and b, d
and b, e
and b, bp
and b, sp

; expect 0
out b

mov a,0xffff
mov b,0xffff
mov c,0xffff
mov d,0xffff
mov e,0xffff
mov bp,0xffff
mov sp,0x0000

and c, c
and c, b
and c, a
and c, d
and c, e
and c, bp
and c, sp

; expect 0
out c

mov a,0xffff
mov b,0xffff
mov c,0xffff
mov d,0xffff
mov e,0xffff
mov bp,0xffff
mov sp,0x0000

and d, d
and d, b
and d, a
and d, c
and d, e
and d, bp
and d, sp

; expect 0
out d


mov a,0xffff
mov b,0xffff
mov c,0xffff
mov d,0xffff
mov e,0xffff
mov bp,0xffff
mov sp,0x0000

and e, e
and e, b
and e, a
and e, c
and e, d
and e, bp
and e, sp

; expect 0
out e


mov a,0xffff
mov b,0xffff
mov c,0xffff
mov d,0xffff
mov e,0xffff
mov bp,0xffff
mov sp,0x0000

and bp, bp
and bp, b
and bp, a
and bp, c
and bp, d
and bp, e
and bp, sp

; expect 0
out bp


mov a,0xffff
mov b,0xffff
mov c,0xffff
mov d,0xffff
mov e,0xffff
mov bp,0xffff
mov sp,0x0000

and sp, sp
and sp, b
and sp, a
and sp, c
and sp, d
and sp, e
and sp, bp

; expect 0
out sp
hlt