#include "nc16_assemble.asm"

in c
call func1
mov a,0x2
hlt

func1:
    call func2
    out c
    ret

func2:
    add c,2
    call func3
    ret

func3:
    mov d,3
    ret
