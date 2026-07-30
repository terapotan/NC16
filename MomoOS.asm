#include "nc16_assemble_OS.asm"


rom_send_command_ionum = 2
buffer_full_int_id = 2
keyboard_int_id = 1
tty_out_id = 0
keyboard_in_id = 0

jmp os_start

os_message_1:
    #d "\nHello, MomoOS World !\nReady for command.\n\0"
    #align 16
command_buffer:
    #res 256
command_buffer_pointer:
    #d 0x0000

interrupt_handler_base_address = 0x5000

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

os_main_loop:
    jmp os_main_loop

; read_rom_data
; 指定したROMからメモリ上にデータを読み込む。
; aレジスタ：読み込むROMの入力アドレス及びROMコントローラコマンド受信アドレス。両者は同じにしておく必要がある。
; bレジスタ：どのアドレスからデータを読み込むか。読み込み起点アドレスを指定する。
; cレジスタ：読み込むデータ長を指定する。
; dレジスタ：どのアドレスに読み込んだデータを書き込むか。

; bpレジスタをbuffer_full検知用レジスタとして使用する。1のときbuffer_full割り込みが起きたことを示す
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
    mov bp,0
    setreadburstmode
    out b ; ROMコントローラへコマンド送信：読み込み起点アドレス
    out c ; ROMコントローラへコマンド送信：読み込むデータ長
    clearintdisableflag
    read_rom_data_loop:
        cmp bp,1
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
    mov bp,1
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

keyboard_int_handler:
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
    mov c,command_buffer
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
        intret

    keyboard_int_handler_input_backspacekey:
        ;mov c,command_buffer
        ;mov memaddr,command_buffer_pointer
        ;add c,[memaddr+0]
        ;;現在のコマンドバッファポインタの一つ前（現在格納されている文字列の一番先端）が指しているところをNULL文字で埋める
        ;sub c,1
        ;mov [c+0],0x0000

        mov memaddr,command_buffer_pointer
        mov c,[memaddr+0] ;コマンドバッファポインタの値をcレジスタに格納
        cmp c,0x0000 ;コマンドバッファポインタが0なら何もしない
        je keyboard_int_handler_intret
        sub c,1
        mov memval,c
        mov [memaddr+0],memval ;読みだした値に1減算した値を再度コマンドバッファポインタに格納
        jmp keyboard_int_handler_intret


    keyboard_int_handler_input_enterkey:
            ;コマンドバッファにNULL文字を追記する

            ;コマンドバッファとコマンドバッファポインタから
            ;次追記すべきメモリアドレスを算出する
            mov c,command_buffer
            mov memaddr,command_buffer_pointer
            add c,[memaddr+0]
            ;コマンドバッファへNULL文字を追記する
            mov [c+0],0x0000

            ;output_stringに入力できる形式に変換する
            ;現状だとコマンドバッファには0x000a,0x0012,0x0023...のように本来1バイトで済む内容を2バイトにして書き込んでいる
            ;output_stringに入力するには、これを0x0a,0x12,0x23...のように連続させたデータにしなければならない
            mov a,command_buffer-2
            mov d,command_buffer-1 ; 書き込みポインタ
            mov e,c
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
                ;jmp STOP
                mov a,tty_out_id
                mov b,command_buffer
                call output_string

                ;コマンドバッファポインタを0に初期化する
                mov memaddr,command_buffer_pointer
                mov memval,0x0000
                mov [memaddr+0],memval

                jmp keyboard_int_handler_intret

STOP:
    hlt