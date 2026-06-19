#include "nc16_assemble.asm"

;ローカル変数テスト

main:
    mov a,0x000a
    mov b,0x000b
    push a
    push b
    pop c
    pop d
    hlt
    call test
    out a
    hlt

test:
    c_test=1
    d_test=c_test+1
    varsum_test = 1*2 + 1
    sub sp,varsum_test
    mov [sp+c_test],0x0c
    mov [sp+d_test],0x01
    add a,b
    add a,[sp+c_test]
    add a,[sp+d_test]
    add sp,varsum_test
    ret
