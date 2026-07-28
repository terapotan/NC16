#include "nc16_assemble_OS.asm"


rom_send_command_ionum = 2
buffer_full_int_id = 2

interrupt_handler_base_address = 0x5000

setoutaddr 1
out 0xffff
hlt

mov memaddr,0x0000

; 割り込みハンドラを設定
num1 = interrupt_handler_base_address+buffer_full_int_id
mov memval,buffer_full_int_handler
mov [memaddr+num1],memval

mov a,rom_send_command_ionum
mov b,0x0000
mov c,0x000a
mov d,0x0900

call read_rom_data
hlt


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