#include "nc16_assemble.asm"
mov a,1
mov b,2
mov c,4
mov d,8
mov e,16
mov bp,32
mov sp,64

or a, a
or a, b
or a, c
or a, d
or a, e
or a, bp
or a, sp

; expect 127(1111111)
out a

mov a,1
mov b,2
mov c,4
mov d,8
mov e,16
mov bp,32
mov sp,64

or b, b
or b, a
or b, c
or b, d
or b, e
or b, bp
or b, sp

; expect 127(1111111)
out b

mov a,1
mov b,2
mov c,4
mov d,8
mov e,16
mov bp,32
mov sp,64

or c, c
or c, b
or c, a
or c, d
or c, e
or c, bp
or c, sp

; expect 127(1111111)
out c

mov a,1
mov b,2
mov c,4
mov d,8
mov e,16
mov bp,32
mov sp,64

or d, d
or d, b
or d, a
or d, c
or d, e
or d, bp
or d, sp

; expect 127(1111111)
out d

mov a,1
mov b,2
mov c,4
mov d,8
mov e,16
mov bp,32
mov sp,64

or e, e
or e, b
or e, a
or e, c
or e, d
or e, bp
or e, sp

; expect 127(1111111)
out e

mov a,1
mov b,2
mov c,4
mov d,8
mov e,16
mov bp,32
mov sp,64

or bp, bp
or bp, b
or bp, a
or bp, c
or bp, d
or bp, e
or bp, sp

; expect 127(1111111)
out bp


mov a,1
mov b,2
mov c,4
mov d,8
mov e,16
mov bp,32
mov sp,64

or sp, sp
or sp, b
or sp, a
or sp, c
or sp, d
or sp, e
or sp, bp

; expect 127(1111111)
out sp
hlt