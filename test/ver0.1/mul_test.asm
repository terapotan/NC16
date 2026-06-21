#include "nc16_assemble.asm"
mov a,1
mov b,2
mov c,3
mov d,4
mov e,5
mov bp,6
mov sp,7

mul a, a
mul a, b
mul a, c
mul a, d
mul a, e
mul a, bp
mul a, sp

; expect 5040
out a

mov a,2
mov b,1
mov c,3
mov d,4
mov e,5
mov bp,6
mov sp,7

mul b, b
mul b, a
mul b, c
mul b, d
mul b, e
mul b, bp
mul b, sp

; expect 5040
out b

mov a,3
mov b,2
mov c,1
mov d,4
mov e,5
mov bp,6
mov sp,7

mul c, c
mul c, b
mul c, a
mul c, d
mul c, e
mul c, bp
mul c, sp

; expect 5040
out c

mov a,4
mov b,2
mov c,3
mov d,1
mov e,5
mov bp,6
mov sp,7

mul d, d
mul d, b
mul d, a
mul d, c
mul d, e
mul d, bp
mul d, sp

; expect 5040
out d


mov a,5
mov b,2
mov c,3
mov d,4
mov e,1
mov bp,6
mov sp,7

mul e, e
mul e, b
mul e, a
mul e, c
mul e, d
mul e, bp
mul e, sp

; expect 5040
out e


mov a,6
mov b,2
mov c,3
mov d,4
mov e,5
mov bp,1
mov sp,7

mul bp, bp
mul bp, b
mul bp, a
mul bp, c
mul bp, d
mul bp, e
mul bp, sp

; expect 5040
out bp


mov a,7
mov b,2
mov c,3
mov d,4
mov e,5
mov bp,6
mov sp,1

mul sp, sp
mul sp, b
mul sp, a
mul sp, c
mul sp, d
mul sp, e
mul sp, bp

; expect 5040
out sp
hlt