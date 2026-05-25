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
xx100000000aaaabbbb 0aaaa1bbb000aaaa000 # add r1, r2
xx100000001aaaabbbb 0aaaa1bbb001aaaa000 # sub r1, r2
xx100000010aaaabbbb 0aaaa1bbb010aaaa000 # mul r1, r2
xx100000011aaaabbbb 0aaaa1bbb011aaaa000 # and r1, r2
xx100000100aaaabbbb 0aaaa1bbb100aaaa000 # or r1, r2
xx100000110aaaabbbb 0aaaa1bbb110aaaa000 # xor r1, r2
xx100000111aaaabbbb 0aaaa1bbb111aaaa000 # div r1, r2

# reg-opd
xx100000000aaaa1111 0aaaa1111000aaaa000 # add r1, opd
xx100000001aaaa1111 0aaaa1111001aaaa000 # sub r1, opd

# reg-[a]
xx100000000aaaa0111 010001aaa000aaaa010 # add r1, [a]
xx100000001aaaa0111 010001aaa001aaaa010 # sub r1, [a]

# not
xx100000101aaaa1111 0aaaa1000101aaaa000 # not r1

# --- データ転送 (mov, in, out) ---
# mov r1, r2
xx100001000aaaabbbb 0bbbb0000000aaaa000 # mov r1, r2

# mov r1, [a]
xx100001000aaaa0111 010000000000aaaa010 # mov r1, [a]

# mov r1, opd
xx100001000aaaa1111 001110000000aaaa000 # mov r1, opd

# mov r1, [opd]
xx100001000aaaa0111 010000000000aaaa100 # mov r1, [opd]

# in / out
xx100001001aaaa1111 010000000000aaaa000 # in r1
xx100001010aaaa1111 0aaaa00000001000000 # out r1

# --- 比較 ---
xx100010010aaaabbbb 0aaaa1bbb0011111000 # cmp r1, r2
xx100010010aaaa1111 0aaaa11110011111000 # cmp r1, opd
"""

fixed_lines = [
    "xx0xxxxxxxxxxxxxxxx 0000000000001111000 # IE=0 (during fetch)",
    "0x10000110111111111 0011100000000111000 # jnz opd (Taken)",
    "1x10000110111111111 0000000000001111000 # jnz opd (Skip)",
    "1x10000111011111111 0011100000000111000 # jz opd (Taken)",
    "0x10000111011111111 0000000000001111000 # jz opd (Skip)",
    "x010000111111111111 0011100000000111000 # jns opd (Taken)",
    "x110000111111111111 0000000000001111000 # jns opd (Skip)",
    "x110001000011111111 0011100000000111000 # js opd (Taken)",
    "x010001000011111111 0000000000001111000 # js opd (Skip)",
    "xx10001000111111111 0011100000000111000 # jmp opd",
    "xx10000100001110001 0000100000001111011 # mov [a], b",
    "xx10000100001110001 0000100000001111101 # mov [opd], b",
    "xx10001001111111111 1000000000001111000 # hlt",
    "xx10001010011111111 0000000000001111000 # nop",
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