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
    #d "MomoOS>\0"
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

systemcall_address_list:
    #res 6 ; システムコール追加/削除時、ここの値も変更すること！

interrupt_handler_base_address = 0x5000
program_data_address = 0x5600
systemcall_address = 0x5121

syscall_handler:
    ;ふつう割り込みハンドラ処理中は割り込み禁止だが
    ;システムコールによる割り込み処理中は割り込みOKとする
    ;そうしないと、各種処理が正常に実行できないからである
    clearintdisableflag
    add e,systemcall_address_list
    mov memaddr,e
    mov e,[memaddr+0]
    call e
    sysret

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

    ; システムコールアドレステーブル設定
    mov a,systemcall_address_list
    mov memaddr,a

    mov memval,input_user_string
    mov [memaddr+0],memval
    mov memval,compare_to_string
    mov [memaddr+1],memval
    mov memval,read_rom_data
    mov [memaddr+2],memval
    mov memval,output_string
    mov [memaddr+3],memval
    mov memval,ascii_to_int
    mov [memaddr+4],memval
    mov memval,int_to_ascii
    mov [memaddr+5],memval

    ; システムコールハンドラアドレス設定
    mov memaddr,systemcall_address
    mov memval,syscall_handler
    mov [memaddr+0],memval



main_loop:
    mov a,tty_out_id
    mov b,os_message_6
    call output_string

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
    call __read_rom_data
    
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
    call __read_rom_data

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

;戻り値
; eレジスタ：正常終了時は0、不正な引数が渡された場合に1を返す。

; eレジスタをbuffer_full検知用レジスタとして使用する。1のときbuffer_full割り込みが起きたことを示す
read_rom_data:

    ;データの書き込み先として0x5600(ユーザーモードのプログラムがアクセスしてはならないメモリ領域)より小さいメモリアドレスを指定していないかチェック
    cmp d,0x5600
    jl read_rom_data_error

;OSがread_rom_dataの機能を利用する場合はこちらをcallする
__read_rom_data:
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

    mov e,0
    ret

read_rom_data_error:
    mov e,1
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


    ;入力文字列がEnterKeyであれば、コマンドバッファの内容をTTYに出力する
    cmp b,keyboard_int_handler_enterkey
    je keyboard_int_handler_input_enterkey

    ;入力文字列がbackspacekeyのとき、コマンドバッファポインタを一つ前に戻す
    ;コマンドバッファへの追記は行わない
    cmp b,keyboard_int_handler_backspacekey
    je keyboard_int_handler_input_backspacekey

    ;コマンドバッファへ追記する

    setoutaddr tty_out_id
    out b ;TTYへ入力文字出力

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
        out b ;TTYへ入力文字出力

        sub c,1
        mov memval,c
        mov [memaddr+0],memval ;読みだした値に1減算した値を再度コマンドバッファポインタに格納
        jmp keyboard_int_handler_intret


    keyboard_int_handler_input_enterkey:
            setoutaddr tty_out_id
            out b ;TTYへ入力文字出力
            
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



; ----------------------------------------------------------
; ascii_to_int
; 数字のASCII文字列（10進数、'0'～'9'のみ。符号には非対応）を
; 数値に変換する。文字列はNULL文字(0x00)で終端されていること。
;
; 引数
; aレジスタ：変換したい文字列の先頭アドレス
;
; 戻り値
; bレジスタ：変換された数値
; cレジスタ：処理結果
;              0 ：成功
;              1 ：'0'～'9'以外の文字が含まれていた（数字として不正）
;              2 ：文字列が空だった（1文字も数字が見つからなかった）
;              3 : aレジスタに指定されたアドレスを読み込む権限がない
;
; 備考
; ・変換結果が65535を超える場合の動作は未定義とする（オーバーフロー検出は行わない）。
; ----------------------------------------------------------
ascii_to_int:

    ;データの読み込み元として0x5600(ユーザーモードのプログラムがアクセスしてはならないメモリ領域)より小さいメモリアドレスを指定していないかチェック
    cmp a,program_data_address
    jl ascii_to_int_error

    __ascii_to_int:
    push d
    push e
    push bp

    mov b,0  ; 変換結果の積算用（戻り値）
    mov d,a  ; 文字列読み出し用のワードアドレスポインタ
    mov bp,0 ; 数字を1文字でも読み込めたかどうかのフラグ(0:未検出 1:検出済み)

    ascii_to_int_loop:
        mov memaddr,d
        mov e,[memaddr+0] ; 1ワード(2文字分)読み出し

        ; ---- 上位8bit(1文字目)の処理 ----
        mov c,e
        and c,0xff00
        shr c,8

        cmp c,0x0000
        je ascii_to_int_end ; 上位8bitがNULL文字＝文字列終端

        ;与えられた文字が数字を表す文字（0,1,2,3,4,5,6,7,8,9）のいずれかであるかどうかチェック
        ;数字を表す文字ではない場合、不正文字が入力されたとして処理を中断。
        cmp c,0x30
        jl ascii_to_int_invalid_char ; '0'未満
        cmp c,0x39
        ja ascii_to_int_invalid_char ; '9'超過


        ; 347という文字列を数値に変換することを考える
        ; bレジスタには3が入っているとする
        ; 手順1:bレジスタに10をかけて元々あった数字を左に一つずらす
        ; 手順2:空いた位に今読み込んだ値を足す。ここでは4が足される
        ; これで十の位まで読めたことになる。同様の手順で一の位も読みだせば、347という文字列が数値に変換される。
        sub c,0x30
        mul b,10
        add b,c
        mov bp,1

        ; ---- 下位8bit(2文字目)の処理 ----
        mov c,e
        and c,0x00ff

        cmp c,0x0000
        je ascii_to_int_end ; 下位8bitがNULL文字＝文字列終端

        ;与えられた文字が数字を表す文字（0,1,2,3,4,5,6,7,8,9）のいずれかであるかどうかチェック
        ;数字を表す文字ではない場合、不正文字が入力されたとして処理を中断。
        cmp c,0x30
        jl ascii_to_int_invalid_char
        cmp c,0x39
        ja ascii_to_int_invalid_char

        sub c,0x30
        mul b,10
        add b,c
        mov bp,1

        add d,1
        jmp ascii_to_int_loop

    ascii_to_int_end:
        cmp bp,0
        je ascii_to_int_empty
        mov c,0
        jmp ascii_to_int_exit

    ascii_to_int_invalid_char:
        mov c,1
        jmp ascii_to_int_exit

    ascii_to_int_empty:
        mov c,2

    ascii_to_int_exit:
        pop bp
        pop e
        pop d
    ascii_to_int_ret_exit:
        ret

    ascii_to_int_error:
        mov c,3
        jmp ascii_to_int_ret_exit

; ----------------------------------------------------------
; int_to_ascii
; 数値を10進数のASCII文字列に変換する。
; 変換結果は指定したメモリ領域に、2文字/ワードの形式
; （上位8bitに1文字目、下位8bitに2文字目）で格納し、
; 文字列の終端にはNULL文字(0x00)を格納する。
;
; 引数
; aレジスタ：文字列に変換したい数値（0～65535の符号なし整数として扱う）
; bレジスタ：変換した文字列を格納するメモリ領域の先頭アドレス
;            （"65535"+NULL文字を格納できるよう、最低3ワード分の
;            空き領域を確保しておくこと）
;
; 戻り値
; cレジスタ：処理結果。
;           0:成功
;           1:bレジスタに指定したアドレスに対し書き込む権限が存在しない
; ----------------------------------------------------------
int_to_ascii_place_table:
    #d 0x2710 ; 10000
    #d 0x03e8 ; 1000
    #d 0x0064 ; 100
    #d 0x000a ; 10
    #d 0x0001 ; 1
int_to_ascii_started:
    #d 0x0000 ; 1文字でも出力済みかどうかのフラグ（先頭の0を省略するために使用）
int_to_ascii_pending:
    #d 0xffff ; 書き込み待ちの文字(上位8bit分)。0xffffは「保留中の文字なし」を表す

int_to_ascii:
    ;データの書き込み先として0x5600(ユーザーモードのプログラムがアクセスしてはならないメモリ領域)より小さいメモリアドレスを指定していないかチェック
    cmp b,program_data_address
    jl int_to_ascii_error

    ; 状態初期化
    ; 呼び出し2回目以降は前回の呼び出しで使った値が残っている
    ; ので初期化しておく必要がある
    mov memaddr,int_to_ascii_started
    mov memval,0x0000
    mov [memaddr+0],memval
 
    mov memaddr,int_to_ascii_pending
    mov memval,0xffff
    mov [memaddr+0],memval
__int_to_ascii:
    push d
    push e
    push bp

    mov bp,0 ; 位取りテーブルの添字（0:10000の位 ～ 4:1の位）

    int_to_ascii_outer_loop:
        ; 現在の位取りの値をテーブルから読み出す
        mov e,bp
        add e,int_to_ascii_place_table
        mov memaddr,e
        mov d,[memaddr+0]

        ; aレジスタから位取りの値(dレジスタ)を繰り返し減算し、その桁の数字をeレジスタに求める
        mov e,0
        int_to_ascii_div_loop:
            ; d（位取りの値）よりa（文字列に変換したい数値）が小さいなら
            ; その位取りの値が表す桁は出力する必要がないので処理を中断する
            ; 542という数字を例にして考える。542は10000と比べて小さい。542に10000の位は必要ないから処理を中断する。
            ; 542は100と比べて大きい。よって除算を実行する。542割る100の商は5であるから、百の位として5を出力する
            cmp a,d
            jl int_to_ascii_div_done
            sub a,d
            add e,1
            jmp int_to_ascii_div_loop
        int_to_ascii_div_done:


        ; eレジスタの値が0になったとして、必ずしもその桁を出力する必要がないわけではない
        ; 例えば5602という値において、十の位は0だが、この0は出力しなければならない。
        ; こういった場合に対応するため、次のロジックで該当の桁を出力すべきか、そうでないか判定する。
        ; 1. 現在文字列の出力を開始しているならば、0であっても出力する。桁の途中に0があるようなケースが該当する。
        ; 2. 1の位の0は必ず出力する
        ; 3. 0でないなら普通に出力。その際、文字列出力中のフラグを1にする。

        ; この桁を出力すべきか判定する（先頭の0は省略。ただし1の位は必ず出力する）
        cmp e,0
        jne int_to_ascii_will_output

        mov memaddr,int_to_ascii_started
        mov c,[memaddr+0]
        cmp c,1
        je int_to_ascii_output_digit ; 既に出力を開始しているなら0も出力する

        cmp bp,4
        je int_to_ascii_output_digit ; 1の位は0であっても必ず出力する

        jmp int_to_ascii_next_digit ; 先頭の0なので出力しない

        int_to_ascii_will_output:
            mov memaddr,int_to_ascii_started
            mov memval,1
            mov [memaddr+0],memval

        int_to_ascii_output_digit:
            add e,0x30 ; 数値をASCII文字コードへ変換

            mov memaddr,int_to_ascii_pending
            mov c,[memaddr+0]
            cmp c,0xffff
            je int_to_ascii_store_pending

            ; 保留中の文字(上位8bit)と今回の文字(下位8bit)を結合して1ワード書き込む
            mul c,256 ;左に8bitシフト
            or c,e
            mov memval,c
            mov memaddr,b
            mov [memaddr+0],memval
            add b,1

            mov memaddr,int_to_ascii_pending
            mov memval,0xffff
            mov [memaddr+0],memval
            jmp int_to_ascii_next_digit

        int_to_ascii_store_pending:
            mov memaddr,int_to_ascii_pending
            mov memval,e
            mov [memaddr+0],memval

        int_to_ascii_next_digit:
            add bp,1
            cmp bp,5
            jl int_to_ascii_outer_loop

    ; 最後にNULL文字を書き込んで文字列を終端する
    mov memaddr,int_to_ascii_pending
    mov c,[memaddr+0]
    cmp c,0xffff
    je int_to_ascii_write_null_only

    ; 保留中の文字が残っている場合、その文字を上位8bit、NULL文字を下位8bitとして書き込む
    mul c,256 ;左に8bitシフト
    mov memval,c
    mov memaddr,b
    mov [memaddr+0],memval
    jmp int_to_ascii_success

    int_to_ascii_write_null_only:
        mov memval,0x0000
        mov memaddr,b
        mov [memaddr+0],memval

    int_to_ascii_success:
        mov c,0

    pop bp
    pop e
    pop d
    int_to_ascii_ret:
    ret

    int_to_ascii_error:
        mov c,1
        jmp int_to_ascii_ret

STOP:
    hlt