; ============================================================
; このファイルは NC16C コンパイラによって自動生成されました。
; 手で編集する場合は再生成時に上書きされる点に注意してください。
; ============================================================
#include "nc16_assemble_USERPROGRAM.asm"

program_start:
    call main
    userret

; ---- 関数 ----
add:
    push bp
    mov bp,sp
    mov a,bp
    add a,2
    mov memaddr,a
    mov a,[memaddr+0]
    push a
    mov a,bp
    add a,3
    mov memaddr,a
    mov a,[memaddr+0]
    mov b,a
    pop a
    add a,b
    jmp _add_end_1
_add_end_1:
    mov sp,bp
    pop bp
    ret

main:
    push bp
    mov bp,sp
    sub sp,3
    mov a,g_a
    push a
    pop a
    push bp
    mov e,0
    syscall
    pop bp
    mov a,b
    mov a,g_b
    push a
    pop a
    push bp
    mov e,0
    syscall
    pop bp
    mov a,b
    mov a,bp
    sub a,2
    mov memaddr,a
    mov a,[memaddr+0]
    push a
    mov a,g_a
    push bp
    mov e,4
    syscall
    pop bp
    pop d
    mov memaddr,d
    mov memval,b
    mov [memaddr+0],memval
    mov a,c
    mov a,bp
    sub a,3
    mov memaddr,a
    mov a,[memaddr+0]
    push a
    mov a,g_b
    push bp
    mov e,4
    syscall
    pop bp
    pop d
    mov memaddr,d
    mov memval,b
    mov [memaddr+0],memval
    mov a,c
    mov a,g_a
    push a
    mov a,g_b
    mov b,a
    pop a
    add a,b
    push a
    mov a,g_output_str
    push a
    pop b
    pop a
    push bp
    mov e,5
    syscall
    pop bp
    mov a,c
    mov a,g_output_str
    push a
    pop b
    push bp
    mov e,3
    syscall
    pop bp
    mov a,c
    mov a,0x0000
    jmp _main_end_2
_main_end_2:
    mov sp,bp
    pop bp
    ret


; ---- グローバル変数 ----
g_output_str:
    #res 16
g_a:
    #res 16
g_b:
    #res 16
