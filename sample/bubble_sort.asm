#include "nc16_assemble.asm"

; 配列を昇順でソートする
; アルゴリズムはバブルソート

main:
    sortarray_main=7
    varsum_main=7+1
    sub sp,varsum_main
    ;配列確保/初期化
    mov [sp+(sortarray_main-0)],0x5
    mov [sp+(sortarray_main-1)],0x1
    mov [sp+(sortarray_main-2)],0x8
    mov [sp+(sortarray_main-3)],0xc
    mov [sp+(sortarray_main-4)],0x2
    mov [sp+(sortarray_main-5)],0x3
    mov [sp+(sortarray_main-6)],0x7
    mov a,sp
    add a,sortarray_main
    mov b,0x7
    call bubble_sort
    hlt


; 配列の合計を求める
; a:合計を求める対象の配列（の0番目の要素のアドレス値）
; b:配列の個数
; c:合計（戻り値）
sum:
    sub b,1
    mov d,0x0 ;配列の添え字
    mov c,0x0 ;合計値を初期化
    ; a[d]を計算しeレジスタに格納
    loop_sum:
        cmp d,b
        ja ret_sum
        mov e,a
        sub e,d
        add c,[e+0] ;c += a[d]
        add d,1
        jmp loop_sum

    ret_sum:
        ret

; a:ソート対象の配列（の0番目の要素のアドレス値）
; b:配列の個数
bubble_sort:

    array_bubble_sort=1
    array_size_bubble_sort=array_bubble_sort+1
    varsum_bubble_sort=1*2+1
    sub sp,varsum_bubble_sort

    sub b,1
    sub a,b ;配列のカーソルを一番最後の配列に持ってくる
    ; 引数をローカル変数に退避させる
    mov [sp+array_bubble_sort],a
    mov [sp+array_size_bubble_sort],b

    ; cレジスタ、dレジスタはカウンタ用の変数として用いる
    mov c,0x0
    mov d,0x0
    for1_bubble_sort:
        ; c<array_size-1"でない"とき
        ; bubble_sortを終了する
            cmp c,b
            jae ret_bubble_sort
            mov d,0x0
        for2_bubble_sort:
            ; d<array_size-1"でない"とき
            ; for2ループを終了する
            cmp d,b
            jae for1_end_bubble_sort
            ; array[d]とarray[d+1]を比較
            ; cmp [a+d],[a+d+1]を実行する
            
            ; eレジスタにa+dを格納
            mov e,d
            add e,a

            ; [a+d]の値をaレジスタに格納
            mov a,[e+0]
            ; aレジスタと[e+1](つまり[a+d]と[a+d+1])を比較する
            mov b,[e+1]
            cmp b,a
            ; [a+d+1]の方が大きかったら、swapする
            ja swap_bubble_sort
            ;aレジスタに退避させた引数を戻す
            mov a,[sp+array_bubble_sort]
            ;bレジスタに退避させた引数を戻す
            mov b,[sp+array_size_bubble_sort]
            for2_end_bubble_sort:
            add d,1
            jmp for2_bubble_sort

            swap_bubble_sort:
                mov b,[e+1]
                mov [e+1],a
                mov [e+0],b

                ;aレジスタに退避させた引数を戻す
                mov a,[sp+array_bubble_sort]
                ;bレジスタに退避させた引数を戻す
                mov b,[sp+array_size_bubble_sort]
                jmp for2_end_bubble_sort
        for1_end_bubble_sort:
            add c,1
            jmp for1_bubble_sort
    
    ret_bubble_sort:
        add sp,varsum_bubble_sort
        ret
