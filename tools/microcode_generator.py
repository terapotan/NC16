#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
microcode_gen.py
=================
CPUNC16 (NC-16) Microcode Generator

"Instruction_Decoder_Specification.md" の Microcode仕様 / CPU Control BUS(CCB)
仕様に基づき、各フィールド（ALU Input1 Select, ALU Input2 Select, ALU function
Select, Register Write Enable, RAM Address Select, RAM Write Enable, flag_write_sw,
HALT, MOR write enable, IR/MOR operand select）を指定するだけで、24bitの
Microcode ROMワードを自動生成するコンソールプログラムです。

Microcodeワードのビット割り当て (24bit):
    [23]    MOR write enable
    [22]    IR operand or MOR operand select
    [21:0]  CPU Control BUS (CCB)

CPU Control BUS (CCB) のビット割り当て (22bit):
    [21]    flag_write_sw
    [20]    HALT
    [19:14] ALU Input1 Select and ALU bypass
              [19:15] ALU Input1 Select (5bit)
              [14]    ALU bypass (0=バイパス / 1=ALU使用)
    [13:11] ALU Input2 Select (3bit)
    [10:8]  ALU function Select (3bit)
    [7:3]   Register Write Enable (5bit)
    [2:1]   RAM Address Select (2bit)
    [0]     RAM Write Enable (1bit)

MOR write enable = 1 のとき、ワードの下位16bit ([15:0]) が MOR へ書き込む値
として扱われ、CCBにはNOP相当が出力されます（[22:16]は未使用/0とします）。

使い方:
    対話モード:      python3 microcode_gen.py
    コマンドライン:   python3 microcode_gen.py build --help
    デコード:        python3 microcode_gen.py decode 0x123456
"""

import argparse
import sys


ALU_INPUT1_SELECT = {
    0b00000: "A register",
    0b00001: "B register",
    0b00010: "C register",
    0b00011: "D register",
    0b00100: "E register",
    0b00101: "BP register",
    0b00110: "SP register",
    0b00111: "operand (オペランド)",
    0b01000: "input_port",
    0b01001: "memory (メモリ)",
    0b01010: "PC register",
    0b01011: "MEMVAL register",
    0b01100: "FLAGS register",
    0b01101: "INTNUM register",
    0b01110: "inaddr register",
    0b01111: "outaddr register",
    0b10000: "buffer",
    0b10001: "buffer_pointer",
    0b10010: "buffer_size",
}

ALU_INPUT2_SELECT = {
    0b000: "A register",
    0b001: "B register",
    0b010: "C register",
    0b011: "D register",
    0b100: "E register",
    0b101: "BP register",
    0b110: "SP register",
    0b111: "operand (オペランド)",
}

ALU_FUNCTION_SELECT = {
    0b000: "Input1 + Input2 (ADD)",
    0b001: "Input1 - Input2 (SUB, 2's complement)",
    0b010: "Input1 * Input2 (MUL)",
    0b011: "Input1 AND Input2",
    0b100: "Input1 OR Input2",
    0b101: "NOT Input1",
    0b110: "Input1 XOR Input2",
    0b111: "Input1 >> Input2 (SHR)",
}

REGISTER_WRITE_ENABLE = {
    0b00000: "A register",
    0b00001: "B register",
    0b00010: "C register",
    0b00011: "D register",
    0b00100: "E register",
    0b00101: "BP register",
    0b00110: "SP register",
    0b00111: "PC register",
    0b01000: "output_port",
    0b01001: "MEMADDR",
    0b01010: "MEMVAL",
    0b01011: "FLAGS",
    0b01100: "INTNUM",
    0b01101: "inaddr",
    0b01110: "outaddr",
    0b01111: "(none / 全レジスタ書き込み無効)",
    0b10000: "buffer",
    0b10001: "buffer_pointer",
    0b10010: "buffer_size",
}

RAM_ADDRESS_SELECT = {
    0b00: "PC",
    0b01: "MEMADDR register + opd",
    0b10: "operand (オペランド)",
    # 0b11 は禁止
}

# 名前(英語ラベル)からコードを引くための逆引き辞書を自動生成
def _reverse(d):
    r = {}
    for code, label in d.items():
        full = label.strip().lower()
        base = label.split(" (")[0].strip().lower()
        r[full] = code
        r[base] = code
        # 括弧内の短縮エイリアス（例: "Input1 + Input2 (ADD)" -> "add"）
        if "(" in label and ")" in label:
            alias = label[label.find("(") + 1: label.find(")")].strip().lower()
            alias = alias.split(",")[0].strip()
            if alias:
                r[alias] = code
        # "A register" のような "<letters> register" 形式なら "a" 等の短縮名も登録
        if base.endswith(" register"):
            short = base[: -len(" register")].strip()
            if short:
                r[short] = code
        r[str(code)] = code
        r[bin(code)] = code
    return r

_R_ALU1 = _reverse(ALU_INPUT1_SELECT)
_R_ALU2 = _reverse(ALU_INPUT2_SELECT)
_R_FUNC = _reverse(ALU_FUNCTION_SELECT)
_R_FUNC.update({
    "add": 0b000, "+": 0b000,
    "sub": 0b001, "-": 0b001,
    "mul": 0b010, "*": 0b010,
    "and": 0b011,
    "or": 0b100,
    "not": 0b101,
    "xor": 0b110,
    "shr": 0b111, "shift": 0b111, ">>": 0b111,
})
_R_REG = _reverse(REGISTER_WRITE_ENABLE)
_R_REG.update({"none": 0b01111, "disable": 0b01111, "no write": 0b01111})
_R_RAM = _reverse(RAM_ADDRESS_SELECT)

MICROCODE_WIDTH = 24
CCB_WIDTH = 22


class MicrocodeError(ValueError):
    pass

# --- 追加修正: 2進数文字列（"0b"プレフィックスなし）にも対応するための入力パーサ -----
def _parse_word_str(raw: str) -> int:
    """
    Microcodeワードの文字列表現をintへ変換する。

    この関数では、
      1. "0x"/"0X"/"0o"/"0O" プレフィックスが付いている場合はそのまま int(raw, 0) で解釈
      2. "0b"/"0B" プレフィックスが付いている場合もそのまま int(raw, 0) で解釈
      3. プレフィックスが無く、文字列が "0" と "1" のみで構成されている場合は
         2進数とみなして int(raw, 2) で解釈する
      4. それ以外（プレフィックス無しの数字列で0/1以外の数字を含む場合など）は
         従来通り int(raw, 0) で10進数として解釈する
    """
    s = raw.strip().replace("_", "")  # 桁区切りの "_" は無視できるようにしておく
 
    # 1. / 2. 明示的なプレフィックスがある場合は従来通りの挙動
    if s.lower().startswith(("0x", "0o", "0b")):
        return int(s, 0)
 
    # 3. プレフィックス無しでも "0"と"1"だけの文字列なら2進数とみなす
    if len(s) > 0 and all(ch in "01" for ch in s):
        return int(s, 2)
 
    # 4. それ以外は従来通り10進数（明示プレフィックス無しの数値）として解釈
    return int(s, 0)

# ---------------------------------------------------------------------------
# Microcode組み立てロジック
# ---------------------------------------------------------------------------

def build_normal_microcode(
    ir_mor_select: int,
    flag_write_sw: int,
    halt: int,
    alu_bypass: int,
    alu_input1: int,
    alu_input2: int,
    alu_function: int,
    reg_write: int,
    ram_addr_sel: int,
    ram_write_enable: int,
) -> int:
    """通常命令実行用のMicrocodeワード(24bit)を組み立てる。"""

    for name, val, maxv in [
        ("ir_mor_select", ir_mor_select, 1),
        ("flag_write_sw", flag_write_sw, 1),
        ("halt", halt, 1),
        ("alu_bypass", alu_bypass, 1),
        ("ram_write_enable", ram_write_enable, 1),
    ]:
        if val not in (0, 1):
            raise MicrocodeError(f"{name} は 0 か 1 で指定してください（指定値: {val}）")

    if alu_input1 not in ALU_INPUT1_SELECT:
        raise MicrocodeError(f"ALU Input1 Select の値が不正です: {alu_input1:#07b}")
    if alu_input2 not in ALU_INPUT2_SELECT:
        raise MicrocodeError(f"ALU Input2 Select の値が不正です（禁止コード）: {alu_input2:#05b}")
    if alu_function not in ALU_FUNCTION_SELECT:
        raise MicrocodeError(f"ALU function Select の値が不正です: {alu_function:#05b}")
    if reg_write not in REGISTER_WRITE_ENABLE:
        raise MicrocodeError(f"Register Write Enable の値が不正です（禁止コード）: {reg_write:#07b}")
    if ram_addr_sel not in RAM_ADDRESS_SELECT:
        raise MicrocodeError(f"RAM Address Select の値が不正です（禁止コード, 0b11は禁止）: {ram_addr_sel:#04b}")

    alu_input1_and_bypass = (alu_input1 << 1) | alu_bypass  # 6bit

    ccb = (
        (flag_write_sw << 21)
        | (halt << 20)
        | (alu_input1_and_bypass << 14)
        | (alu_input2 << 11)
        | (alu_function << 8)
        | (reg_write << 3)
        | (ram_addr_sel << 1)
        | ram_write_enable
    )

    mor_write_enable = 0
    word = (mor_write_enable << 23) | (ir_mor_select << 22) | ccb
    return word


def build_mor_write_microcode(mor_value: int) -> int:
    """MORへの値ロード用のMicrocodeワード(24bit)を組み立てる。"""
    if not (0 <= mor_value <= 0xFFFF):
        raise MicrocodeError(f"MORへの書き込み値は16bit範囲(0-65535)で指定してください（指定値: {mor_value}）")
    mor_write_enable = 1
    word = (mor_write_enable << 23) | (0 << 22) | mor_value
    return word


# ---------------------------------------------------------------------------
# デコード（逆変換）ロジック
# ---------------------------------------------------------------------------

def decode_microcode(word: int) -> str:
    if not (0 <= word < (1 << MICROCODE_WIDTH)):
        raise MicrocodeError(f"Microcodeワードは{MICROCODE_WIDTH}bit範囲で指定してください")

    mor_write_enable = (word >> 23) & 0b1
    lines = []
    lines.append(f"Microcode word         : {word:#08x}  (0b{word:024b})")
    lines.append(f"[23] MOR write enable  : {mor_write_enable}")

    if mor_write_enable:
        mor_value = word & 0xFFFF
        lines.append(f"  -> MOR書き込みモード。CCBにはNOP相当が出力されます。")
        lines.append(f"  -> MORへの書き込み値  : {mor_value:#06x} ({mor_value})")
        return "\n".join(lines)

    ir_mor_select = (word >> 22) & 0b1
    ccb = word & 0x3FFFFF

    flag_write_sw = (ccb >> 21) & 0b1
    halt = (ccb >> 20) & 0b1
    alu1_and_bypass = (ccb >> 14) & 0b111111
    alu_bypass = alu1_and_bypass & 0b1
    alu_input1 = (alu1_and_bypass >> 1) & 0b11111
    alu_input2 = (ccb >> 11) & 0b111
    alu_function = (ccb >> 8) & 0b111
    reg_write = (ccb >> 3) & 0b11111
    ram_addr_sel = (ccb >> 1) & 0b11
    ram_write_enable = ccb & 0b1

    lines.append(f"[22] IR/MOR operand select : {ir_mor_select}  "
                 f"({'MORオペランド' if ir_mor_select else 'IRオペランド'})")
    lines.append(f"[21] flag_write_sw     : {flag_write_sw}")
    lines.append(f"[20] HALT              : {halt}")
    lines.append(f"[19:15] ALU Input1 Select : {alu_input1:#07b} -> "
                 f"{ALU_INPUT1_SELECT.get(alu_input1, '禁止/未定義')}")
    lines.append(f"[14] ALU bypass        : {alu_bypass}  "
                 f"({'ALUを経由してInput1を使用' if alu_bypass else 'ALUをバイパス（レジスタへ直結）'})")
    lines.append(f"[13:11] ALU Input2 Select : {alu_input2:#05b} -> "
                 f"{ALU_INPUT2_SELECT.get(alu_input2, '禁止/未定義')}")
    lines.append(f"[10:8] ALU function Select: {alu_function:#05b} -> "
                 f"{ALU_FUNCTION_SELECT.get(alu_function, '未定義')}")
    lines.append(f"[7:3] Register Write Enable: {reg_write:#07b} -> "
                 f"{REGISTER_WRITE_ENABLE.get(reg_write, '禁止/未定義')}")
    lines.append(f"[2:1] RAM Address Select  : {ram_addr_sel:#04b} -> "
                 f"{RAM_ADDRESS_SELECT.get(ram_addr_sel, '禁止')}")
    lines.append(f"[0] RAM Write Enable   : {ram_write_enable}")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# 出力整形
# ---------------------------------------------------------------------------

def format_result(word: int) -> str:
    bin_str = f"{word:024b}"
    lines = [
        "=" * 60,
        f" 生成されたMicrocode ({MICROCODE_WIDTH}bit)",
        "=" * 60,
        f" 10進数 : {word}",
        f" 16進数 : {word:#08x}",
        f" 2進数  : 0b{bin_str}",
        "-" * 60,
        decode_microcode(word),
        "=" * 60,
    ]
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# 対話（インタラクティブ）モード
# ---------------------------------------------------------------------------

def _choose(prompt: str, options: dict) -> int:
    """options: {code: label} の辞書から番号選択させ、選択されたcodeを返す。"""
    print(f"\n{prompt}")
    items = list(options.items())
    for i, (code, label) in enumerate(items):
        print(f"  [{i}] {label}  (code=0b{code:0{max(1, len(bin(max(options))[2:]))}b})")
    while True:
        raw = input("  番号を選択してください > ").strip()
        if raw.isdigit() and 0 <= int(raw) < len(items):
            return items[int(raw)][0]
        print("  無効な入力です。番号を入力してください。")


def _choose_bit(prompt: str, zero_label: str, one_label: str) -> int:
    print(f"\n{prompt}")
    print(f"  [0] {zero_label}")
    print(f"  [1] {one_label}")
    while True:
        raw = input("  0 または 1 を入力してください > ").strip()
        if raw in ("0", "1"):
            return int(raw)
        print("  無効な入力です。")


def interactive_mode():
    print("#" * 60)
    print("# CPUNC16 Microcode Generator - 対話モード")
    print("#" * 60)

    print("\nどちらのMicrocodeを生成しますか？")
    print("  [1] 通常の命令実行用Microcode (ALU/レジスタ/RAM制御)")
    print("  [2] MOR書き込み用Microcode (MORへ即値をロード)")
    while True:
        mode = input("番号を選択してください > ").strip()
        if mode in ("1", "2"):
            break
        print("無効な入力です。")

    if mode == "2":
        while True:
            raw = input("\nMORに書き込む16bit値を入力してください (10進 or 0x.. 形式) > ").strip()
            try:
                value = int(raw, 0)
                word = build_mor_write_microcode(value)
                break
            except (ValueError, MicrocodeError) as e:
                print(f"入力エラー: {e}")
        print("\n" + format_result(word))
        return

    ir_mor_select = _choose_bit(
        "IR operand or MOR operand select",
        "IRに格納されているオペランドを出力", "MORに格納されているオペランドを出力")

    flag_write_sw = _choose_bit(
        "flag_write_sw",
        "レジスタ入力バスの信号をFLAGSレジスタへ入力",
        "ALUのCarry/Zero/Sign FlagをFLAGSレジスタへ入力")

    halt = _choose_bit("HALT", "クロックを送る（通常動作）", "CPU全体のクロックを停止")

    alu_bypass = _choose_bit(
        "ALU bypass",
        "Input1信号はALUをバイパスしレジスタ入力側へ直結",
        "Input1をALUに入力（ALU経由）")

    alu_input1 = _choose("ALU Input1 Select", ALU_INPUT1_SELECT)
    alu_input2 = _choose("ALU Input2 Select", ALU_INPUT2_SELECT)
    alu_function = _choose("ALU function Select", ALU_FUNCTION_SELECT)
    reg_write = _choose("Register Write Enable", REGISTER_WRITE_ENABLE)
    ram_addr_sel = _choose("RAM Address Select", RAM_ADDRESS_SELECT)
    ram_write_enable = _choose_bit(
        "RAM Write Enable",
        "何もしない",
        "次のクロック立ち上がりでBレジスタの値をRAM Address Selectで選択されたアドレスへ書き込み")

    try:
        word = build_normal_microcode(
            ir_mor_select=ir_mor_select,
            flag_write_sw=flag_write_sw,
            halt=halt,
            alu_bypass=alu_bypass,
            alu_input1=alu_input1,
            alu_input2=alu_input2,
            alu_function=alu_function,
            reg_write=reg_write,
            ram_addr_sel=ram_addr_sel,
            ram_write_enable=ram_write_enable,
        )
    except MicrocodeError as e:
        print(f"\nエラー: {e}")
        sys.exit(1)

    print("\n" + format_result(word))


# ---------------------------------------------------------------------------
# CLI (コマンドライン / バッチ利用)
# ---------------------------------------------------------------------------

def _lookup(reverse_dict, raw):
    """名前(英語ラベル) or 数値(10進/0x/0b) を code(int)へ変換する。"""
    key = str(raw).strip().lower()
    if key in reverse_dict:
        return reverse_dict[key]
    try:
        return int(raw, 0)
    except ValueError:
        raise MicrocodeError(f"'{raw}' はフィールド値として認識できませんでした")


def build_argparser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="microcode_gen.py",
        description="CPUNC16 Microcode自動生成ツール",
    )
    sub = p.add_subparsers(dest="command")

    b = sub.add_parser("build", help="通常命令実行用Microcodeを生成")
    b.add_argument("--ir-mor-select", choices=["ir", "mor"], default="ir",
                    help="IR operand or MOR operand select (default: ir)")
    b.add_argument("--flag-write-sw", type=int, choices=[0, 1], default=0)
    b.add_argument("--halt", type=int, choices=[0, 1], default=0)
    b.add_argument("--alu-bypass", type=int, choices=[0, 1], default=1,
                    help="0=ALUをバイパス, 1=ALUを使用 (default: 1)")
    b.add_argument("--alu-input1", required=True,
                    help="例: 'A register' / 'a' / '0' / '0b00000'")
    b.add_argument("--alu-input2", required=True,
                    help="例: 'B register' / 'b' / '1'")
    b.add_argument("--alu-function", required=True,
                    help="例: 'Input1 + Input2 (ADD)' / 'add' / '0'")
    b.add_argument("--reg-write", required=True,
                    help="例: 'A register' / 'a' / 'none'")
    b.add_argument("--ram-addr-sel", required=True,
                    help="例: 'PC' / 'pc' / '0'")
    b.add_argument("--ram-write-enable", type=int, choices=[0, 1], default=0)

    m = sub.add_parser("mor-write", help="MOR書き込み用Microcodeを生成")
    m.add_argument("value", help="MORへ書き込む16bit値 (10進 or 0x.. 形式)")

    d = sub.add_parser("decode", help="24bit Microcodeワードを人間可読な形にデコード")
    d.add_argument("word", help="Microcodeワード (10進 or 0x.. / 0b.. 形式)")

    sub.add_parser("fields", help="各フィールドの選択肢一覧を表示")

    return p


def print_fields():
    def dump(title, d, width):
        print(f"\n[{title}]")
        for code, label in d.items():
            print(f"  0b{code:0{width}b} ({code:2d}) : {label}")

    dump("ALU Input1 Select (5bit)", ALU_INPUT1_SELECT, 5)
    dump("ALU Input2 Select (3bit)", ALU_INPUT2_SELECT, 3)
    dump("ALU function Select (3bit)", ALU_FUNCTION_SELECT, 3)
    dump("Register Write Enable (5bit)", REGISTER_WRITE_ENABLE, 5)
    dump("RAM Address Select (2bit)", RAM_ADDRESS_SELECT, 2)


def main():
    parser = build_argparser()
    args = parser.parse_args()

    if args.command is None:
        interactive_mode()
        return

    try:
        if args.command == "build":
            word = build_normal_microcode(
                ir_mor_select=1 if args.ir_mor_select == "mor" else 0,
                flag_write_sw=args.flag_write_sw,
                halt=args.halt,
                alu_bypass=args.alu_bypass,
                alu_input1=_lookup(_R_ALU1, args.alu_input1),
                alu_input2=_lookup(_R_ALU2, args.alu_input2),
                alu_function=_lookup(_R_FUNC, args.alu_function),
                reg_write=_lookup(_R_REG, args.reg_write),
                ram_addr_sel=_lookup(_R_RAM, args.ram_addr_sel),
                ram_write_enable=args.ram_write_enable,
            )
            print(format_result(word))

        elif args.command == "mor-write":
            value = int(args.value, 0)
            word = build_mor_write_microcode(value)
            print(format_result(word))

        elif args.command == "decode":
            word = _parse_word_str(args.word)
            print(decode_microcode(word))

        elif args.command == "fields":
            print_fields()

    except MicrocodeError as e:
        print(f"エラー: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()