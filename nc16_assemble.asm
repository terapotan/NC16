
; --- レジスタ定義 ---
; FuncInput1, FuncInput2 で使用される4ビットの値
#subruledef regs {
    a   => 0x0
    b   => 0x1
    c   => 0x2
    d   => 0x3
    e   => 0x4
    bp  => 0x5
    sp  => 0x6
    mem => 0x7
    in  => 0x8
    out => 0x9
    none => 0xf
}
#bankdef nc16bank
{
    addr = 0x0000      
    size = 0x10000     
    outp = 0          
    bits = 16
}
#bank nc16bank

; --- 命令セット定義 ---
; ビット構成: {func:8}{in1:4}{in2:4}{opd:16}

#ruledef {
    ; --- 算術・論理演算 ---
    add {r1: regs},{r2: regs} => 0x00 @ r1 @ r2 @ 0x0000
    add {r1: regs},{opd:u16}  => 0x00 @ r1 @ 0xf @ opd
    add {r1: regs},[a]         => 0x00 @ r1 @ 0x7 @ 0x0000

    sub {r1: regs},{r2: regs} => 0x01 @ r1 @ r2 @ 0x0000
    sub {r1: regs},{opd: u16}  => 0x01 @ r1 @ 0xf @ opd
    sub {r1: regs},[a]         => 0x01 @ r1 @ 0x7 @ 0x0000

    mul {r1: regs},{r2: regs} => 0x02 @ r1 @ r2 @ 0x0000
    mul {r1: regs},{opd: u16}  => 0x02 @ r1 @ 0xf @ opd
    mul {r1: regs},[a]         => 0x02 @ r1 @ 0x7 @ 0x0000

    and {r1: regs},{r2: regs} => 0x03 @ r1 @ r2 @ 0x0000
    and {r1: regs},{opd: u16}  => 0x03 @ r1 @ 0xf @ opd
    and {r1: regs},[a]         => 0x03 @ r1 @ 0x7 @ 0x0000

    or  {r1: regs},{r2: regs} => 0x04 @ r1 @ r2 @ 0x0000
    or  {r1: regs},{opd: u16}  => 0x04 @ r1 @ 0xf @ opd
    or  {r1: regs},[a]         => 0x04 @ r1 @ 0x7 @ 0x0000

    not {r1: regs}             => 0x05 @ r1 @ 0xf @ 0x0000

    xor {r1: regs},{r2: regs} => 0x06 @ r1 @ r2 @ 0x0000
    xor {r1: regs},{opd: u16}  => 0x06 @ r1 @ 0xf @ opd
    xor {r1: regs},[a]         => 0x06 @ r1 @ 0x7 @ 0x0000

    div {r1: regs},{r2: regs} => 0x07 @ r1 @ r2 @ 0x0000
    div {r1: regs},{opd: u16}  => 0x07 @ r1 @ 0xf @ opd
    div {r1: regs},[a]         => 0x07 @ r1 @ 0x7 @ 0x0000

    ; --- データ転送命令 ---
    mov {r1: regs},{r2: regs} => 0x08 @ r1 @ r2 @ 0x0000
    mov {r1: regs},[a]         => 0x08 @ r1 @ 0x7 @ 0x0000
    mov {r1: regs},[{opd: u16}] => 0x08 @ r1 @ 0x7 @ opd
    mov {r1: regs},{opd: u16} => 0x08 @ r1 @ 0xf @ opd
    
    ; メモリ書き込みはBレジスタ固定仕様
    mov [a],b                 => 0x08 @ 0x7 @ 0x1 @ 0x0000
    mov [{opd: u16}],b         => 0x08 @ 0x7 @ 0x1 @ opd

    in  {r1: regs}             => 0x09 @ r1 @ 0xf @ 0x0000
    out {r1: regs}             => 0x0a @ r1 @ 0xf @ 0x0000

    ; --- ジャンプ命令 ---
    ; opdにはラベルまたは16bitアドレスが入る
    jnz {opd: u16}             => 0x0d @ 0xf @ 0xf @ opd
    jz  {opd: u16}             => 0x0e @ 0xf @ 0xf @ opd
    jns {opd: u16}             => 0x0f @ 0xf @ 0xf @ opd
    js  {opd: u16}             => 0x10 @ 0xf @ 0xf @ opd
    jmp {opd: u16}             => 0x11 @ 0xf @ 0xf @ opd

    jnz {r1: regs}             => 0x0d @ r1 @ 0xf @ 0x0000
    jz  {r1: regs}             => 0x0e @ r1 @ 0xf @ 0x0000
    jns {r1: regs}             => 0x0f @ r1 @ 0xf @ 0x0000
    js  {r1: regs}             => 0x10 @ r1 @ 0xf @ 0x0000
    jmp {r1: regs}             => 0x11 @ r1 @ 0xf @ 0x0000

    ; --- 比較・停止 ---
    cmp {r1: regs},{r2: regs} => 0x12 @ r1 @ r2 @ 0x0000
    cmp {r1: regs},{opd: u16}  => 0x12 @ r1 @ 0xf @ opd
    cmp {r1: regs},[a]         => 0x12 @ r1 @ 0x7 @ 0x0000

    hlt                        => 0x13 @ 0xf @ 0xf @ 0x0000
    nop                        => 0x14 @ 0xf @ 0xf @ 0x0000
    lpc                        => 0x15 @ 0xf @ 0xf @ 0x0000

    ; push,call命令はaレジスタとbレジスタの値を破壊する！
    ; pop命令はaレジスタの値を破壊する！
    ; プログラムを組む際は上記項目に注意すること。
    push {opd: u16} => asm{
        sub sp,1
        mov b,{opd}
        mov a,sp
        mov [a],b
    }
    push {r1: regs} => asm{
        sub sp,1
        mov b,{r1}
        mov a,sp
        mov [a],b
    }
    pop {r1: regs} => asm{
        mov a,sp
        mov {r1},[a]
        add sp,1
    }
    call {opd: u16} => asm{
        lpc
        add a,10;push命令、jmp命令の命令長を修正した場合、
        push a
        jmp {opd}
    }
    ret => asm{
        pop a
        jmp a
    }



}
; 初期化
mov sp,0xffff