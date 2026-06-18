
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
    add {r1: regs},[memaddr+{opd:u16}]=> 0x00 @ r1 @ 0x9 @ opd
    add memval,{opd:u16} => 0x00 @ 0xb @ 0xf @ opd

    sub {r1: regs},{r2: regs} => 0x01 @ r1 @ r2 @ 0x0000
    sub {r1: regs},{opd: u16}  => 0x01 @ r1 @ 0xf @ opd
    sub {r1: regs},[memaddr+{opd:u16}]=> 0x01 @ r1 @ 0x9 @ opd

    mul {r1: regs},{r2: regs} => 0x02 @ r1 @ r2 @ 0x0000
    mul {r1: regs},{opd: u16}  => 0x02 @ r1 @ 0xf @ opd
    mul {r1: regs},[memaddr+{opd:u16}]=> 0x02 @ r1 @ 0x9 @ opd

    and {r1: regs},{r2: regs} => 0x03 @ r1 @ r2 @ 0x0000
    and {r1: regs},{opd: u16}  => 0x03 @ r1 @ 0xf @ opd
    and {r1: regs},[memaddr+{opd:u16}]=> 0x03 @ r1 @ 0x9 @ opd

    or  {r1: regs},{r2: regs} => 0x04 @ r1 @ r2 @ 0x0000
    or  {r1: regs},{opd: u16}  => 0x04 @ r1 @ 0xf @ opd
    or  {r1: regs},[memaddr+{opd:u16}]=> 0x04 @ r1 @ 0x9 @ opd

    not {r1: regs}             => 0x05 @ r1 @ 0xf @ 0x0000

    xor {r1: regs},{r2: regs} => 0x06 @ r1 @ r2 @ 0x0000
    xor {r1: regs},{opd: u16}  => 0x06 @ r1 @ 0xf @ opd
    xor {r1: regs},[a]         => 0x06 @ r1 @ 0x7 @ 0x0000
    xor {r1: regs},[memaddr+{opd:u16}]=> 0x06 @ r1 @ 0x9 @ opd

    shr {r1: regs},{r2: regs} => 0x07 @ r1 @ r2 @ 0x0000
    shr {r1: regs},{opd: u16}  => 0x07 @ r1 @ 0xf @ opd
    shr {r1: regs},[a]         => 0x07 @ r1 @ 0x7 @ 0x0000
    shr {r1: regs},[memaddr+{opd:u16}]=> 0x07 @ r1 @ 0x9 @ opd

    ; --- データ転送命令 ---
    mov {r1: regs},{r2: regs} => 0x08 @ r1 @ r2 @ 0x0000
    mov {r1: regs},[memaddr+{opd: u16}] => 0x08 @ r1 @ 0x9 @ opd
    mov memval,[memaddr+{opd: u16}] => 0x08 @ 0xb @ 0x9 @ opd
    mov {r1: regs},[{opd: u16}] => 0x08 @ r1 @ 0x7 @ opd
    mov {r1: regs},{opd: u16} => 0x08 @ r1 @ 0xf @ opd
    
    ; メモリ書き込みはmemaddrレジスタ固定仕様
    mov memaddr,{r1: regs} => 0x08 @ 0xa @ r1 @ 0x0000
    mov memval,{r1: regs} => 0x08 @ 0xb @ r1 @ 0x0000
    mov [memaddr+{opd: u16}],memval => 0x08 @ 0xa @ 0xa @ opd
    mov memval,[{opd: u16}]         => 0x08 @ 0xb @ 0x7 @ opd

    mov {r1: regs},[{r2: regs}+{opd: u16}] => asm{
        mov memaddr,r2
        mov r1,[memaddr+opd]
    }
    mov [{r1: regs}+{opd: u16}],{r2: regs} => asm{
        mov memaddr,r1
        mov memval,r2
        mov [memaddr+opd],memval
    }

    in  {r1: regs}             => 0x09 @ r1 @ 0xf @ 0x0000
    out {r1: regs}             => 0x0a @ r1 @ 0xf @ 0x0000

    ; --- ジャンプ命令 ---
    ; opdにはラベルまたは16bitアドレスが入る
    jnc {opd: u16}             => 0x0b @ 0xf @ 0xf @ opd
    jc  {opd: u16}             => 0x0c @ 0xf @ 0xf @ opd
    jnz {opd: u16}             => 0x0d @ 0xf @ 0xf @ opd
    jz  {opd: u16}             => 0x0e @ 0xf @ 0xf @ opd
    jns {opd: u16}             => 0x0f @ 0xf @ 0xf @ opd
    js  {opd: u16}             => 0x10 @ 0xf @ 0xf @ opd
    jmp {opd: u16}             => 0x11 @ 0xf @ 0xf @ opd
    je  {opd: u16}             => 0x16 @ 0xf @ 0xf @ opd
    jne {opd: u16}             => 0x17 @ 0xf @ 0xf @ opd
    ja  {opd: u16}             => 0x18 @ 0xf @ 0xf @ opd
    jae {opd: u16}             => 0x19 @ 0xf @ 0xf @ opd
    jl  {opd: u16}             => 0x1a @ 0xf @ 0xf @ opd
    jle {opd: u16}             => 0x1b @ 0xf @ 0xf @ opd

    jnc {r1: regs}             => 0x0b @ r1 @ 0xf @ 0x0000
    jc  {r1: regs}             => 0x0c @ r1 @ 0xf @ 0x0000
    jnz {r1: regs}             => 0x0d @ r1 @ 0xf @ 0x0000
    jz  {r1: regs}             => 0x0e @ r1 @ 0xf @ 0x0000
    jns {r1: regs}             => 0x0f @ r1 @ 0xf @ 0x0000
    js  {r1: regs}             => 0x10 @ r1 @ 0xf @ 0x0000
    jmp {r1: regs}             => 0x11 @ r1 @ 0xf @ 0x0000
    je  {r1: regs}             => 0x16 @ r1 @ 0xf @ 0x0000
    jne {r1: regs}             => 0x17 @ r1 @ 0xf @ 0x0000
    ja  {r1: regs}             => 0x18 @ r1 @ 0xf @ 0x0000
    jae {r1: regs}             => 0x19 @ r1 @ 0xf @ 0x0000
    jl  {r1: regs}             => 0x1a @ r1 @ 0xf @ 0x0000
    jle {r1: regs}             => 0x1b @ r1 @ 0xf @ 0x0000

    jmp memval                 => 0x11 @ 0xb @ 0xf @ 0x0000

    ; --- 比較・停止 ---
    cmp {r1: regs},{r2: regs} => 0x12 @ r1 @ r2 @ 0x0000
    cmp {r1: regs},{opd: u16}  => 0x12 @ r1 @ 0xf @ opd
    cmp {r1: regs},[memaddr+{opd:u16}]=> 0x12 @ r1 @ 0x9 @ opd


    hlt                        => 0x13 @ 0xf @ 0xf @ 0x0000
    nop                        => 0x14 @ 0xf @ 0xf @ 0x0000
    lpc                        => 0x15 @ 0xf @ 0xf @ 0x0000

    ; push,call命令はaレジスタとbレジスタの値を破壊する！
    ; pop命令はaレジスタの値を破壊する！
    ; プログラムを組む際は上記項目に注意すること。
    push {opd: u16} => asm{
        sub sp,1
        mov memval,{opd}
        mov memaddr,sp
        mov [memaddr],memval
    }
    push {r1: regs} => asm{
        sub sp,1
        mov memval,{r1}
        mov memaddr,sp
        mov [memaddr+0],memval
    }
    pop {r1: regs} => asm{
        mov memaddr,sp
        mov {r1},[memaddr+0]
        add sp,1
    }
    call {opd: u16} => asm{
        lpc
        add memval,0xc
        ; push memval
        sub sp,1
        mov memaddr,sp
        mov [memaddr+0],memval
        jmp {opd}
    }
    ret => asm{
        ; pop memval
        mov memaddr,sp
        mov memval,[memaddr+0]
        add sp,1
        jmp memval
    }



}


jmp nc16_assemble_start

; 除算を計算する
; cレジスタに割られる数、dレジスタに割る数を格納し
; cレジスタに余り、dレジスタに商を除算結果として格納する
; 符号付き整数には対応していない
div:
    mov a,0
div_inner_loop_28437293731:
    add a,1
    sub c,d
    jns div_inner_loop_28437293731
    sub a,1
    add c,d
    mov d,a
    ret

nc16_assemble_start:
; 初期化
mov sp,0xffff