import itertools
import sys

# 定義: NC-16 レジスタ
# (名前, 4bit値, 3bit値)
REGISTERS = [
    ("a",  "0000", "000"),
    ("b",  "0001", "001"),
    ("c",  "0010", "010"),
    ("d",  "0011", "011"),
    ("e",  "0100", "100"),
    ("bp", "0101", "101"),
    ("sp", "0110", "110"),
]

raw_template = """
# --- 算術・論理演算 (add, sub, mul, and, or, xor, div) ---
# reg-reg
xxx100000000aaaabbbb 0aaaa1bbb000aaaa000 # add r1, r2
xxx100000001aaaabbbb 0aaaa1bbb001aaaa000 # sub r1, r2
xxx100000010aaaabbbb 0aaaa1bbb010aaaa000 # mul r1, r2
xxx100000011aaaabbbb 0aaaa1bbb011aaaa000 # and r1, r2
xxx100000100aaaabbbb 0aaaa1bbb100aaaa000 # or r1, r2
xxx100000110aaaabbbb 0aaaa1bbb110aaaa000 # xor r1, r2
xxx100000111aaaabbbb 0aaaa1bbb111aaaa000 # shr r1, r2

# reg-opd
xxx100000000aaaa1111 0aaaa1111000aaaa000 # add r1, opd
xxx100000001aaaa1111 0aaaa1111001aaaa000 # sub r1, opd
xxx100000010aaaa1111 0aaaa1111010aaaa000 # mul r1, opd
xxx100000011aaaa1111 0aaaa1111011aaaa000 # and r1, opd
xxx100000100aaaa1111 0aaaa1111100aaaa000 # or r1, opd
xxx100000110aaaa1111 0aaaa1111110aaaa000 # xor r1, opd
xxx100000111aaaa1111 0aaaa1111111aaaa000 # shr r1, opd

# reg-[a]
xxx100000000aaaa0111 010001aaa000aaaa010 # add r1, [a]
xxx100000001aaaa0111 010001aaa001aaaa010 # sub r1, [a]
xxx100000010aaaa0111 010001aaa010aaaa010 # mul r1, [a]
xxx100000011aaaa0111 010001aaa011aaaa010 # and r1, [a]
xxx100000100aaaa0111 010001aaa100aaaa010 # or r1, [a]
xxx100000110aaaa0111 010001aaa110aaaa010 # sub r1, [a]
xxx100000111aaaa0111 010001aaa111aaaa010 # shr r1, [a]

# not
xxx100000101aaaa1111 0aaaa1000101aaaa000 # not r1

# --- データ転送 (mov, in, out) ---
# mov r1, r2
xxx100001000aaaabbbb 0bbbb0000000aaaa000 # mov r1, r2

# mov r1, [a]
xxx100001000aaaa0111 010010000000aaaa010 # mov r1, [a]

# mov r1, opd
xxx100001000aaaa1111 001110000000aaaa000 # mov r1, opd

# mov r1, [opd]
xxx100001000aaaa0111 010010000000aaaa100 # mov r1, [opd]

# in / out
xxx100001001aaaa1111 010000000000aaaa000 # in r1
xxx100001010aaaa1111 0aaaa00000001000000 # out r1

# --- 比較 ---
xxx100010010aaaabbbb 0aaaa1bbb0011111000 # cmp r1, r2
xxx100010010aaaa1111 0aaaa11110011111000 # cmp r1, opd

# jmp,jcc命令
00x100001011aaaa1111 0aaaa00000000111000 # jnc r1 (Taken)
10x100001011aaaa1111 0000000000001111000 # jnc r1 (Skip)
10x100001100aaaa1111 0aaaa00000000111000 # jc r1 (Taken)
00x100001100aaaa1111 0000000000001111000 # jc r1 (Skip)
x0x100001101aaaa1111 0aaaa00000000111000 # jnz r1 (Taken)
x1x100001101aaaa1111 0000000000001111000 # jnz r1 (Skip)
x1x100001110aaaa1111 0aaaa00000000111000 # jz r1 (Taken)
x0x100001110aaaa1111 0000000000001111000 # jz r1 (Skip)
xx0100001111aaaa1111 0aaaa00000000111000 # jns r1 (Taken)
xx1100001111aaaa1111 0000000000001111000 # jns r1 (Skip)
xx1100010000aaaa1111 0aaaa00000000111000 # js r1 (Taken)
xx0100010000aaaa1111 0000000000001111000 # js r1 (Skip)
xxx100010001aaaa1111 0aaaa00000000111000 # jmp r1
x1x100010110aaaa1111 0aaaa00000000111000 # je r1 (Taken)
x0x100010110aaaa1111 0000000000001111000 # je r1 (Skip)
x0x100010111aaaa1111 0aaaa00000000111000 # jne r1(Taken)
x1x100010111aaaa1111 0000000000001111000 # jne r1(Skip)
x00100011000aaaa1111 0aaaa00000000111000 # ja r1 (Taken)
xxx100011000aaaa1111 0000000000001111000 # ja r1 (Skip)
x00100011001aaaa1111 0aaaa00000000111000 # jae r1 (Taken)
x10100011001aaaa1111 0aaaa00000000111000 # jae r1 (Taken)
xxx100011001aaaa1111 0000000000001111000 # jae r1 (Skip)
x01100011010aaaa1111 0aaaa00000000111000 # jl r1 (Taken)
xxx100011010aaaa1111 0000000000001111000 # jl r1 (Skip)
x01100011011aaaa1111 0aaaa00000000111000 # jle r1 (Taken)
x10100011011aaaa1111 0aaaa00000000111000 # jle r1 (Taken) 
xxx100011011aaaa1111 0000000000001111000 # jle r1 (Skip)
"""

fixed_lines = [
    "xxx0xxxxxxxxxxxxxxxx 0000000000001111000 # IE=0 (during fetch)",
    "00x10000101111111111 0011100000000111000 # jnc opd (Taken)",
    "10x10000101111111111 0000000000001111000 # jnc opd (Skip)",
    "10x10000110011111111 0011100000000111000 # jc opd (Taken)",
    "00x10000110011111111 0000000000001111000 # jc opd (Skip)",
    "x0x10000110111111111 0011100000000111000 # jnz opd (Taken)",
    "x1x10000110111111111 0000000000001111000 # jnz opd (Skip)",
    "x1x10000111011111111 0011100000000111000 # jz opd (Taken)",
    "x0x10000111011111111 0000000000001111000 # jz opd (Skip)",
    "xx010000111111111111 0011100000000111000 # jns opd (Taken)",
    "xx110000111111111111 0000000000001111000 # jns opd (Skip)",
    "xx110001000011111111 0011100000000111000 # js opd (Taken)",
    "xx010001000011111111 0000000000001111000 # js opd (Skip)",
    "xxx10001000111111111 0011100000000111000 # jmp opd",
    "x1x10001011011111111 0011100000000111000 # je opd (Taken)",
    "x0x10001011011111111 0000000000001111000 # je opd (Skip)",
    "x0x10001011111111111 0011100000000111000 # jne opd(Taken)",
    "x1x10001011111111111 0000000000001111000 # jne opd(Skip)",
    "x0010001100011111111 0011100000000111000 # ja opd (Taken)",
    "xxx10001100011111111 0000000000001111000 # ja opd (Skip)",
    "x0010001100111111111 0011100000000111000 # jae opd (Taken)",
    "x1010001100111111111 0011100000000111000 # jae opd (Taken)",
    "xxx10001100111111111 0000000000001111000 # jae opd (Skip)",
    "x0110001101011111111 0011100000000111000 # jl opd (Taken)",
    "xxx10001101011111111 0000000000001111000 # jl opd (Skip)",
    "x0110001101111111111 0011100000000111000 # jle opd (Taken)",
    "x1010001101111111111 0011100000000111000 # jle opd (Taken)", 
    "xxx10001101111111111 0000000000001111000 # jle opd (Skip)",  
    "xxx10000100001110001 0000100000001111011 # mov [a], b",
    "xxx10000100001110001 0000100000001111101 # mov [opd], b",
    "xxx10001001111111111 1000000000001111000 # hlt",
    "xxx10001010011111111 0000000000001111000 # nop",
    "xxxx1111111111111111 0000000000001111000 # invaild",
    "xxx10001010111111111 0101000000000000000 # lpc",
]

def expand():
    
    with open(sys.argv[1],mode='w') as f:
        # 固定行をまず出力
        for line in fixed_lines:
            f.write(line+"\n")

        # テンプレートを走査
        for line in raw_template.strip().split('\n'):
            if not line or line.startswith('#'):
                f.write(line+"\n")
                continue
            
            # r1(aaaa) と r2(bbbb) 両方ある場合 (7x7=49通り)
            if "aaaa" in line and "bbbb" in line:
                for r1, r2 in itertools.product(REGISTERS, REGISTERS):
                    name1, a4, a3 = r1
                    name2, b4, b3 = r2

                    new_line = line.replace("aaaa", a4).replace("bbbb", b4).replace("bbb", b3)
                    new_line = new_line.replace("r1", name1).replace("r2", name2)
                    f.write(new_line+"\n")

            # r1(aaaa) のみある場合 (7通り)
            elif "aaaa" in line:
                for r1 in REGISTERS:
                    name1, a4, a3 = r1

                    new_line = line.replace("aaaa", a4).replace("aaa", a3)
                    new_line = new_line.replace("r1", name1)
                    f.write(new_line+"\n")
            else:
                f.write(line+"\n")

if __name__ == "__main__":
    expand()