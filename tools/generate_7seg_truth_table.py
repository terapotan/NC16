def generate_7seg_truth_table():
    # 7セグメント表示のパターン定義 (g f e d c b a)
    # a: 2^0, b: 2^1, c: 2^2, d: 2^3, e: 2^4, f: 2^5, g: 2^6
    seg_map = {
        0: "0111111",
        1: "0000110",
        2: "1011011",
        3: "1001111",
        4: "1100110",
        5: "1101101",
        6: "1111101",
        7: "0000111",
        8: "1111111",
        9: "1101111"
    }

    print("# 入力(8bit)  出力(一の位7bit + 十の位7bit) # 10進数表記")
    print("-" * 55)

    for i in range(100):
        # 入力を8ビットの2進数文字列に変換
        input_bin = format(i, '08b')
        
        # 十の位と一の位を計算
        tens = i // 10
        units = i % 10
        
        # 指定されたルール：左側が一の位、右側が十の位
        output_bin = seg_map[units] + seg_map[tens]
        
        # フォーマットして出力
        print(f"{input_bin} {output_bin} # {i:02d}")

if __name__ == "__main__":
    generate_7seg_truth_table()
