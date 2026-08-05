#include "nc16_assemble_USERPROGRAM.asm"
tty_out_id = 0
jmp program_start

message_1:
    #d "This is user program!\n\0"
    #align 16
program_start:
    mov a,0xffff
    setoutaddr 1
    out a

    mov a,tty_out_id
    mov b,message_1
    mov e,3
    syscall
    userret