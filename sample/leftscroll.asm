#include "nc16_assemble.asm"

; 入力したビット列を出力ポートに表示し、その表示を左に横スクロールさせるプログラム
; 一番端まで来たらループする

in a
main:
    out a
    mul a,0x2 ;一つ横に移動する
    jc carryplus
    jmp main

carryplus:
    add a,1 ;溢れた分を一つ右側に戻す
    jmp main