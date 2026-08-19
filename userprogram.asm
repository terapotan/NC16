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
    mov b,str1
    mov e,output_string
    syscall
    mov sp,0xfb00
    hlt
    userret


str1:
    #d "Program Started!\n\0"
    #align 16