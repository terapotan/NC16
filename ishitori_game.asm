#include "nc16_assemble.asm"
; 石取りゲーム
; お互いに1～3個の石を取って、最後に石を取った方の負け
; 人間が先手、CPUが後手
; output_port上位4ビットはゲームの状態を表している
; 各ビットが1であるときの意味は次の通り
; 15:INPUT_WAIT:人間の入力待機中である
; 14:CPU_THINKING:CPUの思考中である
; 13:CPU_WIN:ゲームの結果はCPUの勝利である
; 12:HUMAN_WIN:ゲームの結果は人間の勝利である

; それ以外のoutput_portは、石の数を表す。




; 以下の手順で動作する
; 1. 起動して入力待機中になったら、取る石の数をinput_port経由で1～3の間で入力する
; 入力形式は以下の通り（ボタンのone,two,threeを押す）
; 1個石を取る：000 0000 0000 0001
; 2個石を取る：000 0000 0000 0010
; 3個石を取る：000 0000 0000 0100
; これ以外の値が入力された場合、入力待機中に再度戻る。
; 2. CPUが石を取る数を思考する。
; 3. 手順1に戻って繰り返し。


mov d,4
mov a,0x8014 ;石の数の初期値+入力待機中 初期値は20個としている
out a

; 入力待機
input_loop:
    in b
    add b,0 ;ここでbの値がゼロならZero flagが1になる
    jz input_loop

; 何かしらの値が入力された
; input_waitランプを消灯
and a,0x0fff
or a,0x0000
out a

cmp b,0x0001
je input_1
cmp b,0x0002
je input_2
cmp b,0x0004
je input_3


re_input:
    ;入力値が想定値でなかったため、入力待機中表示に戻して再度入力待機
    and a,0x0fff
    or a,0x8000
    out a
    jmp input_loop

input_1:
    mov b,1 ;人間が取った石の数は1つ
    jmp cpu_thinking
input_2:
    mov b,2 ;人間が取った石の数は2つ
    jmp cpu_thinking
input_3:
    mov b,3 ;人間が取った石の数は3つ
    jmp cpu_thinking

cpu_thinking:
    ; 入力値が現在の石の個数を超えている場合は再入力を要求する
    cmp a,b
    jl re_input
    ;人間が取った石の数を引き、石の数表示を更新する
    sub a,b
    mov c,a
    and c,0x0fff
    jz cpu_win ;ここで石の数がゼロになるということは人間の負け。つまりCPUの勝ち。

    ;CPU思考中モードにステータス表示を更新する
    and a,0x0fff
    or a,0x4000
    out a

    ;(N-1) % 4を計算する
    mov c,a
    and c,0x0fff
    sub c,1
    mov e,a
    call div
    mov a,e
    mov d,4
    cmp c,0
    jnz cpu_take_stone
    sub a,1 ;CPUは必敗の状態にあるので何個取ってもダメ。仕方ないので1つ取っておく
    jmp cpu_result_check

cpu_take_stone:
    sub a,c
    jmp cpu_result_check

cpu_result_check:
    mov c,a
    and c,0x0fff
    jz human_win ;ここで石の数がゼロになるということはCPUの負け。つまり人間の勝ち。

    ;入力待機モードにステータス表示を更新する
    and a,0x0fff
    or a,0x8000
    out a

    jmp input_loop

cpu_win:
    and a,0x0fff
    or a,0x2000
    out a
    hlt

human_win:
    and a,0x0fff
    or a,0x1000
    out a
    hlt