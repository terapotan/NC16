#include "nc16_assemble_USERPROGRAM.asm"
tty_out_id = 0
program_start:
    ;mov a,0xffff
    ;setoutaddr 1
    ;out a
    mov memaddr,0x0900
    mov memval,[memaddr+0]

    mov a,message_2
    mov e,0
    syscall

    mov a,message_3
    mov e,0
    syscall

    mov a,message_2
    mov b,message_3
    mov e,1
    syscall

    cmp c,0
    je not_equall
    mov a,tty_out_id
    mov b,message_5
    mov e,3
    syscall
    userret
    
not_equall:
    mov a,tty_out_id
    mov b,message_4
    mov e,3
    syscall
    userret

message_1:
    #d "This is user program!\n\0"
    #align 16
message_2:
    #res 128
    #align 16
message_3:
    #res 128
    #align 16
message_4:
    #d "NOT_EQUALL\n\0"
    #align 16
message_5:
    #d "EQUALL\n\0"
    #align 16