#include "nc16_assemble.asm"

; output_portが0xffffで止まればテスト成功
; 0x0000で止まった場合テスト失敗
mov a,0
out a

mov a,1
mov b,2
mov c,3
mov d,4
mov e,5
mov bp,6
mov sp,7

cmp a,2
jl L1_a
hlt

L1_a:
cmp b,2
je L2_a
hlt

L2_a:
cmp c,2
ja L3_a
hlt

L3_a:
cmp d,2
ja L4_a
hlt

L4_a:
cmp e,2
ja L5_a
hlt

L5_a:
cmp bp,2
ja L6_a
hlt

L6_a:
cmp sp,2
ja L8_a
hlt

L8_a:
mov a,0xffff
out a
hlt
