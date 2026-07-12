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

TMP_FILE_PATH="./Instruction_Decorder.txt"
IMBD_FILE_PATH="./IMBD.txt"
INSTRUCTION_CLASS_FILE_PATH="./Instruction_Class.txt"
MICROCODE_ROM_FILE_PATH="./MicrocodeROM.bin"
MICROCODE_BYTES = 3


# 次の形式で実行
# 第一引数：出力先ファイル名
# 第二引数：入力ファイル名
# ./decorder_text_output.py ./machinecode_to_microcode.txt


def convert_binary_string_to_binary(binary_string):
    return bytes(int(binary_string[i:i+8], 2) for i in range(0, len(binary_string), 8))

def expand_registers():
    raw_template = open(sys.argv[1],mode='r',encoding='utf-8').read()
    
    with open(TMP_FILE_PATH,mode='w',encoding="utf-8") as f:

        for line in raw_template.strip().split('\n'):
            # #もしくは空行の場合単に無視する
            if not line or line.startswith('#'):
                continue
            
            # r1(aaaa) と r2(bbbb) 両方ある場合
            if "aaaa" in line and "bbbb" in line:
                for r1, r2 in itertools.product(REGISTERS, REGISTERS):
                    name1, a4, a3 = r1
                    name2, b4, b3 = r2

                    new_line = line.replace("aaaa", a4).replace("bbbb", b4).replace("bbb", b3)
                    new_line = new_line.replace("r1", name1).replace("r2", name2)
                    f.write(new_line+"\n")

            # r1(aaaa) のみある場合
            elif "aaaa" in line:
                for r1 in REGISTERS:
                    name1, a4, a3 = r1

                    new_line = line.replace("aaaa", a4).replace("aaa", a3)
                    new_line = new_line.replace("r1", name1)
                    f.write(new_line+"\n")
            else:
                f.write(line+"\n")

def export_IMBD_ITSD_MicrocodeROM():
    microcode_list = []
    before_machine_code = ""
    now_machine_code = ""
    before_comment = ""
    now_comment = ""
    before_class_num = ""
    now_class_num = ""

    all_text = open(TMP_FILE_PATH,mode='r',encoding='utf-8').read()
    IMBD_file = open(IMBD_FILE_PATH,mode='w',encoding="utf-8")
    Instruction_Class_file = open(INSTRUCTION_CLASS_FILE_PATH,mode='w',encoding="utf-8")
    Microcode_ROM_file = open(MICROCODE_ROM_FILE_PATH,mode='wb')

    for line in all_text.strip().split('\n'):
        body = line.split('#')[0]
        now_comment = line.split('#')[1]
        line_list = body.split(' ')
        now_machine_code = line_list[0]
        now_class_num = line_list[2]

        #一番最初の読み込みは比較すべき相手が存在しないから
        #比較処理（現在読み込んでいる機械語と前読み込んだ機械語が等しいか）をスキップする
        if before_machine_code == "" :
            microcode_list.append(line_list[1])
            before_machine_code = now_machine_code
            before_comment = now_comment
            before_class_num = now_class_num
            continue

        #前読み込んだ機械語と現在読み込んだ機械語が異なる場合
        #IMBD,Microcode_ROMへの書き込みを行う
        if before_machine_code != now_machine_code:
            base_address = Microcode_ROM_file.tell() // MICROCODE_BYTES
            IMBD_file.write(before_machine_code + " " + format(base_address,'016b') + " #" + before_comment + "\n")
            Instruction_Class_file.write(before_machine_code + " " + format(int(before_class_num),'08b') + " #" + before_comment + "\n")
            for microcode in microcode_list:
                Microcode_ROM_file.write(convert_binary_string_to_binary(microcode))

            microcode_list.clear()
            before_machine_code = now_machine_code
            before_comment = now_comment
            before_class_num = now_class_num
            microcode_list.append(line_list[1])
            continue
        else:
            before_machine_code = now_machine_code
            before_comment = now_comment
            before_class_num = now_class_num
            microcode_list.append(line_list[1])
            continue   


if __name__ == "__main__":
    expand_registers()
    export_IMBD_ITSD_MicrocodeROM()