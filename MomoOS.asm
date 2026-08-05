#include "nc16_assemble_OS.asm"


rom_send_command_ionum = 2

rom1_send_command_ionum = 3
rom2_send_command_ionum = 4
rom3_send_command_ionum = 5

buffer_full_int_id = 2
keyboard_int_id = 1
tty_out_id = 0
keyboard_in_id = 0

jmp os_start

os_message_1:
    #d "\nHello, MomoOS World !\nReady for command.\n\0"
    #align 16
os_message_2:
    #d "equall!\0"
    #align 16
os_message_3:
    #d "not equall!\0"
    #align 16
os_message_4:
    #d "The file you are trying to load is not a program.\n\0"
    #align 16
os_message_5:
    #d "Load complete.\n\0"
    #align 16
os_message_6:
    #d "SYSCALL_CALLED.\n\0"
    #align 16

command_buffer_addr:
    #d 0x0000 ;キーボード入力された文字列を格納するためのメモリ領域（コマンドバッファ）のアドレス
command_buffer_pointer:
    #d 0x0000 ;現在コマンドバッファにおいてどこまで文字列が入力されているか指し示す値（コマンドバッファポインタ）
user_program_size:
    #d 0x0000
os_load_romnum:
    #d 0x0000 ;プログラムを読み込むrom番号。一時的に使用する変数。
command_buffer:
    #res 256
program_header:
    #res 3
os_command_help:
    #d "help\0"
    
    #align 16
os_command_load_rom1:
    #d "load rom1\0"
    #align 16
os_command_load_rom2:
    #d "load rom2\0"
    #align 16
os_command_load_rom3:
    #d "load rom3\0"
    #align 16
os_command_run:
    #d "run\0"
    #align 16
os_command_not_found:
    #d "command not found.\n\0"
    #align 16

interrupt_handler_base_address = 0x5000
program_data_address = 0x5600

syscall_handler:
    mov a,tty_out_id
    mov b,os_message_6
    call output_string
    switchusermode
    hlt
    intret

os_start:
    setoutaddr 1
    out 0xffff
    mov a,tty_out_id
    mov b,os_message_1
    call output_string

    mov memaddr,0x0000

    ; 割り込みハンドラを設定
    num1 = interrupt_handler_base_address+buffer_full_int_id
    mov memval,buffer_full_int_handler
    mov [memaddr+num1],memval

    num2 = interrupt_handler_base_address+keyboard_int_id
    mov memval,keyboard_int_handler
    mov [memaddr+num2],memval

    num3= interrupt_handler_base_address+511
    mov memval,syscall_handler
    mov [memaddr+num3],memval

main_loop:
    mov a,command_buffer
    call input_user_string

    ;各コマンド文字列との比較
    mov a,command_buffer
    mov b,os_command_help
    call compare_to_string
    cmp c,1
    je os_command_help_process

    mov a,command_buffer
    mov b,os_command_load_rom1
    call compare_to_string
    cmp c,1
    je os_command_load_rom1_process

    mov a,command_buffer
    mov b,os_command_load_rom2
    call compare_to_string
    cmp c,1
    je os_command_load_rom2_process

    mov a,command_buffer
    mov b,os_command_load_rom3
    call compare_to_string
    cmp c,1
    je os_command_load_rom3_process

    mov a,command_buffer
    mov b,os_command_run
    call compare_to_string
    cmp c,1
    je os_command_run_process

    jmp os_command_not_found_process

os_command_help_process:
    mov a,tty_out_id
    mov b,os_command_help
    call output_string
    jmp main_loop
os_command_load_rom1_process:
    mov memaddr,os_load_romnum
    mov memval,rom1_send_command_ionum
    mov [memaddr+0],memval
    jmp load_program_data_from_rom

os_command_load_rom2_process:
    mov memaddr,os_load_romnum
    mov memval,rom2_send_command_ionum
    mov [memaddr+0],memval
    jmp load_program_data_from_rom

os_command_load_rom3_process:
    mov memaddr,os_load_romnum
    mov memval,rom3_send_command_ionum
    mov [memaddr+0],memval
    jmp load_program_data_from_rom

os_command_run_process:
    usercall program_data_address
    jmp main_loop

os_command_not_found_process:
    mov a,tty_out_id
    mov b,os_command_not_found
    call output_string
    jmp main_loop




load_program_data_from_rom:
    ; 最初の6バイトを読み出す
    mov memaddr,os_load_romnum
    mov a,[memaddr+0]
    mov b,0x0000
    mov c,3
    mov d,program_header
    call read_rom_data
    
    ; 識別子チェック
    mov b,program_header
    mov a,[b+0]
    cmp a,0xff02
    jne program_load_faild
    mov a,[b+1]
    cmp a,0x2019
    jne program_load_faild

    ; プログラムのサイズを読み出す
    mov c,[b+2] 

    mov memaddr,os_load_romnum
    mov a,[memaddr+0]
    mov b,0x0003
    mov d,program_data_address
    call read_rom_data

    mov a,tty_out_id
    mov b,os_message_5
    call output_string
    jmp main_loop

program_load_faild:
    mov a,tty_out_id
    mov b,os_message_4
    call output_string
    jmp main_loop



hlt



; input_user_string
; ユーザーからのキーボード入力を取得する
; aレジスタ：キーボード入力を保持するメモリ領域のアドレス

;FIXME:input_user_stringには最大入力可能文字数のチェック機構が存在しない。aレジスタで指定した入力文字列
;を保持するメモリ領域が256文字までしか格納できなかったとする。このとき256文字以上は入力できないようにするべきだが
;現状のプログラムでは入力できてしまう。256文字以上入力すると何が起きるかというと、無関係のメモリ領域を破壊してしまう。
;大抵の場合プログラムを破壊し、正常に実行できなくなるだろう。
;早急に修正すること。

input_user_string:
    mov memaddr,command_buffer_addr
    mov memval,a
    mov [memaddr+0],memval ;command_buffer_addrに文字列を格納すべきメモリ領域のアドレスを格納

    mov bp,1 ;キーボード割り込みハンドラを有効化
    input_user_str_loop:
        cmp bp,0 ;キーボード割り込み処理が終わった
        jne input_user_str_loop
    
    ret


;compare_to_string
;二つの文字列を比較する

; aレジスタ：比較したい文字列が確保されているメモリ領域の先頭アドレス
; bレジスタ：比較したい文字列が確保されているメモリ領域の先頭アドレス
; cレジスタ：二つの文字列が等しければ1、等しくなければ0を返す。
compare_to_string:

    compare_to_string_loop:
        mov memaddr,a
        mov d,[memaddr+0] ;文字列1、文字読み出し

        mov memaddr,b
        mov e,[memaddr+0] ;文字列2,文字読み出し

        mov bp,d
        and bp,0xff00
        cmp bp,0x0000 ;0x00XX、上位8bitがNULL文字であった場合
        je compare_to_string_char_zero

        cmp d,e
        je compare_to_string_char_eq
        jne compare_to_string_char_noteq

        compare_to_string_char_zero:
            ;文字列1が0x00XXのとき、文字列2も0x00XXの形式になっているかどうか検証する
            mov bp,e
            and bp,0xff00
            cmp bp,0x0000 ;0x00XX、上位8bitがNULL文字であった場合
            je compare_to_string_string_eq
            jne compare_to_string_char_noteq


        compare_to_string_char_eq:
            mov bp,d
            and bp,0x00ff
            cmp bp,0x0000 ;0xXX00、下位8bitがNULL文字であった場合            
            je compare_to_string_string_eq

            add a,1
            add b,1
            jmp compare_to_string_loop
        
        compare_to_string_char_noteq:
            mov c,0
            ret

        compare_to_string_string_eq:
            mov c,1
            ret


; read_rom_data
; 指定したROMからメモリ上にデータを読み込む。
; aレジスタ：読み込むROMの入力アドレス及びROMコントローラコマンド受信アドレス。両者は同じにしておく必要がある。
; bレジスタ：どのアドレスからデータを読み込むか。読み込み起点アドレスを指定する。
; cレジスタ：読み込むデータ長を指定する。
; dレジスタ：どのアドレスに読み込んだデータを書き込むか。

; eレジスタをbuffer_full検知用レジスタとして使用する。1のときbuffer_full割り込みが起きたことを示す
read_rom_data:
    ;bufferレジスタ関連の初期化処理を行う
    setzerobufferpointer
    setbuffersize c

    ;準備が完了したためROMコントローラに送信開始信号を送信する
    ;アドレスをセットして割り込みが来て、アドレスが変化するのを防ぐため
    ;コマンドの送信が完了するまで割り込み禁止とする。
    setintdisableflag
    setinaddr a
    setoutaddr a
    mov e,0
    setreadburstmode
    out b ; ROMコントローラへコマンド送信：読み込み起点アドレス
    out c ; ROMコントローラへコマンド送信：読み込むデータ長
    clearintdisableflag
    read_rom_data_loop:
        cmp e,1
        jl read_rom_data_loop
    ;bufferレジスタから指定のメモリ番地にデータを転送する
    clearreadburstmode
    setzerobufferpointer

    mov a,0
    read_rom_data_loop_2:
        buffertomemval
        mov memaddr,d
        mov [memaddr+0],memval
        add d,1
        add a,1
        incbufferpointer
        cmp a,c
        jl read_rom_data_loop_2
    ret

buffer_full_int_handler:
    ;割り込みが発生したことを通知
    mov e,1
    intret


; output_string:TTY上に文字列を表示する。表示する文字列はメモリ上に格納する。
; 文字列は\0(NULL文字)で終わらせること。
; 引数
; aレジスタ：TTYの出力アドレス
; bレジスタ：表示する文字列が格納されているメモリ番地

output_string:
    ; カウント用にcレジスタを使うため、cレジスタをスタックに退避させる
    ; メモリからのデータ読み出し用にdレジスタを使うため、dレジスタをスタックに退避させる
    push c
    push d
    push e

    mov c,b

    output_string_loop:
        ; 1ワード読み出し
        mov memaddr,c
        mov d,[memaddr+0]
        mov e,d

        ;上位8ビットを読み出してdレジスタに格納
        and d,0xff00
        shr d,8

        ;dがNULL文字なら読み込みを終了する
        cmp d,0x0000
        je output_string_exit

        setoutaddr a
        out d

        ;下位8ビットを読みだしてeレジスタに格納
        and e,0x00ff

        ;eがNULL文字なら読み込みを終了する
        cmp e,0x0000
        je output_string_exit

        setoutaddr a
        out e

        add c,1
        jmp output_string_loop

    output_string_exit:
        pop e
        pop d
        pop c
        ret


; bpレジスタが1であるとき、このハンドラを有効化する
; それ以外の値であるとき、このハンドラは実行されない
keyboard_int_handler:
    cmp bp,1
    jne keyboard_int_handler_skip

    keyboard_int_handler_enterkey = 0x0a
    keyboard_int_handler_backspacekey = 0x08
    push a
    push b
    push c
    push d
    push e

    setinaddr keyboard_in_id
    in b ;キーボードから入力文字取り込み
    setoutaddr tty_out_id
    out b ;TTYへ入力文字出力

    ;入力文字列がEnterKeyであれば、コマンドバッファの内容をTTYに出力する
    cmp b,keyboard_int_handler_enterkey
    je keyboard_int_handler_input_enterkey

    ;入力文字列がbackspacekeyのとき、コマンドバッファポインタを一つ前に戻す
    ;コマンドバッファへの追記は行わない
    cmp b,keyboard_int_handler_backspacekey
    je keyboard_int_handler_input_backspacekey

    ;コマンドバッファへ追記する

    ;コマンドバッファとコマンドバッファポインタから
    ;次追記すべきメモリアドレスを算出する
    mov memaddr,command_buffer_addr
    mov c,[memaddr+0]
    mov memaddr,command_buffer_pointer
    add c,[memaddr+0]

    ;コマンドバッファへ現在の入力文字を追記する
    mov [c+0],b
   
    ;コマンドバッファポインタの値を更新する
    mov memaddr,command_buffer_pointer
    mov c,[memaddr+0] ;コマンドバッファポインタの値をcレジスタに格納
    add c,1
    mov memval,c
    mov [memaddr+0],memval ;読みだした値に1加算した値を再度コマンドバッファポインタに格納

    keyboard_int_handler_intret:
        pop e
        pop d
        pop c
        pop b
        pop a
    keyboard_int_handler_skip:
        intret

    keyboard_int_handler_input_backspacekey:
        mov memaddr,command_buffer_pointer
        mov c,[memaddr+0] ;コマンドバッファポインタの値をcレジスタに格納
        cmp c,0x0000 ;コマンドバッファポインタが0なら何もしない
        je keyboard_int_handler_intret
        sub c,1
        mov memval,c
        mov [memaddr+0],memval ;読みだした値に1減算した値を再度コマンドバッファポインタに格納
        jmp keyboard_int_handler_intret


    keyboard_int_handler_input_enterkey:
            ;コマンドバッファのアドレスを読み出す
            mov memaddr,command_buffer_addr
            mov c,[memaddr+0]
            mov e,c

            ;コマンドバッファとコマンドバッファポインタから
            ;次追記すべきメモリアドレスを算出する
            mov memaddr,command_buffer_pointer
            add c,[memaddr+0]
            ;コマンドバッファへNULL文字を追記する
            mov [c+0],0x0000

            ;output_stringに入力できる形式に変換する
            ;現状だとコマンドバッファには0x000a,0x0012,0x0023...のように本来1バイトで済む内容を2バイトにして書き込んでいる
            ;output_stringに入力するには、これを0x0a,0x12,0x23...のように連続させたデータにしなければならない
            sub e,1
            mov d,e ; 書き込みポインタ(command_buffer -1)
            sub e,1
            mov a,e ; 読み出しポインタ(command_buffer -2)
            mov e,c
            ;jmp STOP
            keyboard_int_handler_input_enterkey_loop:
                add a,2
                add d,1
                cmp a,e
                ja keyboard_int_handler_string_output

                mov memaddr,a
                mov b,[memaddr+0] ;上位8ビット
                mov c,[memaddr+1] ;下位8ビット

                mul b,256 ; bを左に8ビットシフト
                and c,0x00ff ; 下位8ビット以外は使わないので上位8ビットはゼロクリアしておく
                or b,c

                mov memval,b
                mov memaddr,d
                mov [memaddr+0],memval ;変換したデータはコマンドバッファに上書きする形で書き込む
                jmp keyboard_int_handler_input_enterkey_loop
            
            keyboard_int_handler_string_output:

                ;コマンドバッファポインタを0に初期化する
                mov memaddr,command_buffer_pointer
                mov memval,0x0000
                mov [memaddr+0],memval

                mov bp,0 ;キーボード入力処理終了を通知する
                jmp keyboard_int_handler_intret

STOP:
    hlt