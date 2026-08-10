#include "nc16_assemble_USERPROGRAM.asm"
tty_out_id = 0
input_user_string=0
compare_to_string=1
read_rom_data=2
output_string=3
ascii_to_int=4
int_to_ascii=5

program_start:
    mov a,message_2
    mov e,input_user_string
    syscall
    mov a,message_2
    mov e,ascii_to_int
    syscall
    add b,10
    mov a,b
    mov b,message_3
    mov e,int_to_ascii
    syscall
    mov a,tty_out_id
    mov b,message_3
    mov e,output_string
    syscall
    mov a,tty_out_id
    mov b,enter_str
    mov e,output_string
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
enter_str:
    #d "\n\0"
    #align 16