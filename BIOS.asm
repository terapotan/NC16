#include "nc16_assemble.asm"

os_rom_send_command_ionum = 2
buffer_full_int_id = 2

interrupt_handler_base_address = 0x5000
mov memaddr,0x0000

; 割り込みハンドラを設定
num1 = interrupt_handler_base_address+buffer_full_int_id
mov memval,buffer_full_int_handler
mov [memaddr+num1],memval

jmp bios_start


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

bios_message_1:
    #d "Powered by NC-16 CPU / Created by Momotera.\n\0"
    #align 16
bios_message_2:
    #d "BIOS started successfully.\n\0"
    #align 16
bios_message_3:
    #d "Searching for operating system...\n\0"
    #align 16
bios_message_4:
    #d "Operating system found.\n\0"
    #align 16
bios_message_5:
    #d "[ERROR] No bootable OS found.\nPlease load a bootable OS into OS_ROM and press the RESET button.\n\nNote: If this message persists after loading, verify that the first 4 bytes of the OS are 0x2421 0x8f2a. Use osassembler.py to generate a valid OS binary.\n\0"
    #align 16
bios_message_6:
    #d "OS loading complete.\n\0"
    #align 16
bios_message_7:
    #d "Starting operating system.\n\0"
    #align 16
bios_message_8:
    #d "Loading operating system...\n\0"
    #align 16
os_header:
    #res 3

bios_start:
    mov a,0
    mov b,bios_message_1
    call output_string
    mov b,bios_message_2
    call output_string
    mov b,bios_message_3
    call output_string

    ; 最初の6バイトを読み出す
    mov a,os_rom_send_command_ionum
    mov b,0x0000
    mov c,3
    mov d,os_header
    call read_rom_data
    
    ; 識別子チェック
    mov b,os_header
    mov a,[b+0]
    cmp a,0xff21
    jne os_not_found_error
    mov a,[b+1]
    cmp a,0x8f2a
    jne os_not_found_error

    ; OSのサイズを読み出す
    mov c,[b+2]

    ; OSが見つかった旨のメッセージを出力
    mov a,0
    mov b,bios_message_4
    call output_string

    ; OSの読み込みを行う
    mov b,bios_message_8
    call output_string    

    mov a,os_rom_send_command_ionum
    mov b,0x0003
    mov d,0x500
    call read_rom_data

    ; OSの読み込み完了の旨のメッセージ出力
    mov a,0
    mov b,bios_message_6
    call output_string    

    ; OS起動
    mov a,0
    mov b,bios_message_7
    call output_string

    jmp 0x500



; OSが見つからなかった
os_not_found_error:
    mov a,0
    mov b,bios_message_5
    call output_string
    hlt