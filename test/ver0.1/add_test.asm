#include "nc16_assemble.asm"
mov a,1
mov b,2
mov c,3
mov d,4
mov e,5
mov bp,6
mov sp,7

add a, a
add a, b
add a, c
add a, d
add a, e
add a, bp
add a, sp

; expect 29
out a

mov a,1
mov b,2
mov c,3
mov d,4
mov e,5
mov bp,6
mov sp,7

add b, b
add b, a
add b, c
add b, d
add b, e
add b, bp
add b, sp

; expect 30
out b

mov a,1
mov b,2
mov c,3
mov d,4
mov e,5
mov bp,6
mov sp,7

add c, c
add c, b
add c, a
add c, d
add c, e
add c, bp
add c, sp

; expect 31
out c

mov a,1
mov b,2
mov c,3
mov d,4
mov e,5
mov bp,6
mov sp,7

add d, d
add d, b
add d, a
add d, c
add d, e
add d, bp
add d, sp

; expect 32
out d


mov a,1
mov b,2
mov c,3
mov d,4
mov e,5
mov bp,6
mov sp,7

add e, e
add e, b
add e, a
add e, c
add e, d
add e, bp
add e, sp

; expect 33
out e


mov a,1
mov b,2
mov c,3
mov d,4
mov e,5
mov bp,6
mov sp,7

add bp, bp
add bp, b
add bp, a
add bp, c
add bp, d
add bp, e
add bp, sp

; expect 34
out bp


mov a,1
mov b,2
mov c,3
mov d,4
mov e,5
mov bp,6
mov sp,7

add sp, sp
add sp, b
add sp, a
add sp, c
add sp, d
add sp, e
add sp, bp

; expect 35
out sp
hlt