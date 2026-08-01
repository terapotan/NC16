import sys
import subprocess
import struct
import os


def assemble(input_file: str, output_file: str) -> None:
    # customasm を呼び出してアセンブル
    result = subprocess.run(
        ["customasm", input_file, "-o", output_file],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        # アセンブル失敗時は customasm のエラー内容をそのまま表示して終了
        sys.stderr.write(result.stdout)
        sys.stderr.write(result.stderr)
        sys.exit(result.returncode)

    # 出力バイナリを読み込む
    with open(output_file, "rb") as f:
        binary_data = f.read()

    byte_size = len(binary_data)
    if byte_size % 2 != 0:
        sys.stderr.write(
            f"警告: 出力バイナリのサイズが奇数です ({byte_size} bytes)。"
            "2で割った値は切り捨てられます。\n"
        )

    word_count = byte_size // 2

    # ヘッダ: 0xff02, 0x2019, word_count (各16bit）
    header = struct.pack(">HHH", 0xff02, 0x2019, word_count)

    # ヘッダを先頭に付与して書き戻す
    with open(output_file, "wb") as f:
        f.write(header + binary_data)


def main():
    if len(sys.argv) != 3:
        sys.stderr.write(f"使い方: {sys.argv[0]} <入力ファイル> <出力ファイル>\n")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    if not os.path.exists(input_file):
        sys.stderr.write(f"エラー: 入力ファイルが見つかりません: {input_file}\n")
        sys.exit(1)

    assemble(input_file, output_file)
    print(f"アセンブル成功: {output_file} にヘッダを付与しました。")


if __name__ == "__main__":
    main()