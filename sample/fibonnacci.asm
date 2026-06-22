#include "nc16_assemble.asm"

;フィボナッチ数を求めるプログラム
;フィボナッチ数列のinput_port項目を求める

main:
    in c
    call fibonacci
    out d
    hlt


;cを引数、dを戻り値として使う
fibonacci:
    cmp c,1
    jle zeroorone
    mov a,2;aを項数として扱う
    mov b,0;a-2項前の値
    mov e,1;a-1項前の値
    
    ; 以下a項目の値を求める
    ; a-2項前とa-1項前の値を足してa項目の値を求める
    loop:
        mov d,0 ;dをクリアしておく。前の計算結果を消去する。
        add d,b
        add d,e
        ; a-2項前、a-1項前の値を更新する
        mov b,e
        mov e,d

        add a,1
        cmp a,c
        jle loop
    
    ret

    ;1以下のときは項数と数が一致するので項数をそのまま返す
    zeroorone:
        mov d,c
        ret
