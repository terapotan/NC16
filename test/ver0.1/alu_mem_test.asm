#include "nc16_assemble.asm"

mov memaddr,0x1000
mov memval,0x3
mov [memaddr+3],memval

mov a,3
mov b,3
mov c,3
mov d,3
mov e,3
mov bp,3
mov sp,3

add a,[memaddr+3] ;6
sub a,[memaddr+3] ;3
mul a,[memaddr+3] ;9
and a,[memaddr+3] ;1
xor a,[memaddr+3] ;2
or a,[memaddr+3]  ;3
mul a,[memaddr+3] ;9
mul a,[memaddr+3] ;27
shr a,[memaddr+3] ;3

; expect 3
out a

add b,[memaddr+3] ;6
sub b,[memaddr+3] ;3
mul b,[memaddr+3] ;9
and b,[memaddr+3] ;1
xor b,[memaddr+3] ;2
or b,[memaddr+3]  ;3
mul b,[memaddr+3] ;9
mul b,[memaddr+3] ;27
shr b,[memaddr+3] ;3

; expect 3
out b


add c,[memaddr+3] ;6
sub c,[memaddr+3] ;3
mul c,[memaddr+3] ;9
and c,[memaddr+3] ;1
xor c,[memaddr+3] ;2
or c,[memaddr+3]  ;3
mul c,[memaddr+3] ;9
mul c,[memaddr+3] ;27
shr c,[memaddr+3] ;3

; expect 3
out c


add d,[memaddr+3] ;6
sub d,[memaddr+3] ;3
mul d,[memaddr+3] ;9
and d,[memaddr+3] ;1
xor d,[memaddr+3] ;2
or d,[memaddr+3]  ;3
mul d,[memaddr+3] ;9
mul d,[memaddr+3] ;27
shr d,[memaddr+3] ;3

; expect 3
out d


add e,[memaddr+3] ;6
sub e,[memaddr+3] ;3
mul e,[memaddr+3] ;9
and e,[memaddr+3] ;1
xor e,[memaddr+3] ;2
or e,[memaddr+3]  ;3
mul e,[memaddr+3] ;9
mul e,[memaddr+3] ;27
shr e,[memaddr+3] ;3

; expect 3
out e


add bp,[memaddr+3] ;6
sub bp,[memaddr+3] ;3
mul bp,[memaddr+3] ;9
and bp,[memaddr+3] ;1
xor bp,[memaddr+3] ;2
or bp,[memaddr+3]  ;3
mul bp,[memaddr+3] ;9
mul bp,[memaddr+3] ;27
shr bp,[memaddr+3] ;3

; expect 3
out bp


add sp,[memaddr+3] ;6
sub sp,[memaddr+3] ;3
mul sp,[memaddr+3] ;9
and sp,[memaddr+3] ;1
xor sp,[memaddr+3] ;2
or sp,[memaddr+3]  ;3
mul sp,[memaddr+3] ;9
mul sp,[memaddr+3] ;27
shr sp,[memaddr+3] ;3

; expect 3
out sp
hlt