#include "nc16_assemble.asm"
mov a,27
sub a,a
out a

mov b,27
sub b,b
out b

mov c,27
sub c,c
out c

mov d,27
sub d,d
out d

mov e,27
sub e,e
out e

mov bp,27
sub bp,bp
out bp

mov sp,27
sub sp,sp
out sp

hlt

mov a,27
mov b,2
mov c,3
mov d,4
mov e,5
mov bp,6
mov sp,7

sub a, b
sub a, c
sub a, d
sub a, e
sub a, bp
sub a, sp

; expect 0
out a


mov a,2
mov b,27
mov c,3
mov d,4
mov e,5
mov bp,6
mov sp,7

sub b, a
sub b, c
sub b, d
sub b, e
sub b, bp
sub b, sp

; expect 0
out b

mov a,3
mov b,2
mov c,27
mov d,4
mov e,5
mov bp,6
mov sp,7

sub c, b
sub c, a
sub c, d
sub c, e
sub c, bp
sub c, sp

; expect 0
out c

mov a,4
mov b,2
mov c,3
mov d,27
mov e,5
mov bp,6
mov sp,7

sub d, b
sub d, a
sub d, c
sub d, e
sub d, bp
sub d, sp

; expect 0
out d


mov a,5
mov b,2
mov c,3
mov d,4
mov e,27
mov bp,6
mov sp,7

sub e, b
sub e, a
sub e, c
sub e, d
sub e, bp
sub e, sp

; expect 0
out e


mov a,6
mov b,2
mov c,3
mov d,4
mov e,5
mov bp,27
mov sp,7

sub bp, b
sub bp, a
sub bp, c
sub bp, d
sub bp, e
sub bp, sp

; expect 0
out bp


mov a,7
mov b,2
mov c,3
mov d,4
mov e,5
mov bp,6
mov sp,27

sub sp, b
sub sp, a
sub sp, c
sub sp, d
sub sp, e
sub sp, bp

; expect 0
out sp
hlt