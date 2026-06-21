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
je L1_a
hlt

L1_a:
cmp a,b
jl L2_a
hlt

L2_a:
cmp a,c
jl L3_a
hlt

L3_a:
cmp a,d
jl L4_a
hlt

L4_a:
cmp a,d
jl L5_a
hlt

L5_a:
cmp a,e
jl L6_a
hlt

L6_a:
cmp a,bp
jl L7_a
hlt

L7_a:
cmp a,sp
jl L8_a
hlt

L8_a:
mov a,0xffff
out a
hlt

