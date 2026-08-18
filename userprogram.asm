#include "nc16_assemble_USERPROGRAM.asm"
tty_out_id = 0
input_user_string=0
compare_to_string=1
read_rom_data=2
output_string=3
ascii_to_int=4
int_to_ascii=5
divide=6
random=7


program_start:

;    mov b,message_1
;    mov e,output_string
;    syscall
;
;    cmp c,0
;    je success_show
;    cmp c,1
;    je failed_show
;
;    ;userret
;
;

loop:
    mov e,random
    syscall

    mov b,message_2
    mov e,int_to_ascii
    syscall

    mov b,message_2
    mov e,output_string
    syscall

    mov b,enter_str
    mov e,output_string
    syscall

    jmp loop   


    mov a,message_2
    mov e,input_user_string
    syscall
    mov a,message_3
    mov e,input_user_string
    syscall

    mov a,message_2
    mov e,ascii_to_int
    syscall
    mov memaddr,divide_1
    mov memval,b
    mov [memaddr+0],memval

    mov a,message_3
    mov e,ascii_to_int
    syscall
    mov memaddr,divide_2
    mov memval,b
    mov [memaddr+0],memval

    mov memaddr,divide_1
    mov a,[memaddr+0]
    mov memaddr,divide_2
    mov b,[memaddr+0]
    mov e,divide
    syscall

    mov memaddr,quotient
    mov memval,c
    mov [memaddr+0],memval

    mov memaddr,remainder
    mov memval,d
    mov [memaddr+0],memval


    mov a,c
    mov b,quotient_str
    mov e,int_to_ascii
    syscall

    mov memaddr,remainder
    mov a,[memaddr+0]
    mov b,remainder_str
    mov e,int_to_ascii
    syscall

    mov b,quotient_text
    mov e,output_string
    syscall

    mov b,quotient_str
    mov e,output_string
    syscall

    mov b,enter_str
    mov e,output_string
    syscall

    mov b,remainder_text
    mov e,output_string
    syscall
    
    mov b,remainder_str
    mov e,output_string
    syscall

    mov b,enter_str
    mov e,output_string
    syscall
    exit:
    userret

;    setoutaddr 1
;    mov a,message_2
;    mov e,input_user_string
;    syscall
;    mov a,message_2
;    mov e,ascii_to_int
;    syscall
;    add b,10
;    mov a,b
;    mov b,0x1200
;    mov e,int_to_ascii
;    syscall
;    cmp c,0
;    je success_show
;    cmp c,1
;    je failed_show
;
;    mov a,tty_out_id
;    mov b,message_3
;    mov e,output_string
;    syscall
;    mov a,tty_out_id
;    mov b,enter_str
;    mov e,output_string
;    syscall
;
;    userret

success_show:
    mov b,success
    mov e,output_string
    syscall
    userret

failed_show:
    mov b,failed
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
divide_1:
    #d 0x0000
divide_2:
    #d 0x0000
quotient:
    #d 0x0000
remainder:
    #d 0x0000
quotient_str:
    #res 20
    #align 16
remainder_str:
    #res 20
    #align 16
success:
    #d "Systemcall Success!\n\0"
    #align 16
failed:
    #d "Systemcall failed!\n\0"
    #align 16
quotient_text:
    #d "quotient:\0"
    #align 16
remainder_text:
    #d "remainder:\0"
    #align 16
enter_str:
    #d "\n\0"
    #align 16