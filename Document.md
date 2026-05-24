以下、ドキュメント暫定版。実装していない項目も含まれる。
# NC-16 
## 概要
NC-16はLogitism-evolution上で動作する16ビットCPUです。CPU動作中であっても、配線一本一本の値を確認することができ、デバッグや内部挙動を追うのに最適な構成となっています。ブラックボックスになっている箇所がないため、やる気さえあればハードウェアレベルまでNC-16の挙動を追うことが可能です。
なお、NC-16の名前は**N**an**C**hatte-**16**bitCPUから来ています。
## 表記法
1. [10:5]オペランド　上位10ビットから上位5ビットはオペランドを表します**最下位ビットを0ケタ目としてビット数を数えていることに注意してください。**ただし単にnビットのデータがあると言ったときには、n桁のビットが存在することを表すものとします。この表記法はLogitism-evolution上のビット数の表記に由来しています。
2. [20:10]0b0000000011　上位20ビットから上位10ビットまでの値は2進数で0000000011です。
3. [0] 0b1　上位0ビット目の値は2進数で1です。
4. 禁止　この値が真理値表の出力欄/意味欄に記載されていた場合、その出力に対応する入力はしてはなりません。禁止出力に対応する入力が行われた場合の動作は未定義であり、NC-16はどのような動作も行う可能性があります。
5. X　Don't Careを表します。
6. 真理値表において他の行と同入力で、出力値が異なる場合、先に書かれた行の出力値を優先するものとします。例えば以下の真理値表では1行目と2行目の記載が衝突しますが、1行目の記載が優先されるため、入力1011に対する出力は1となります。

|bit4|bit3|bit2|bit1|出力|
|:--:|:--:|:--:|:--:|:--:|
|1|0|1|1|1|
|X|X|X|X|0|
# NC-16　アーキテクチャ
## レジスタ・I/Oポート
6つの汎用レジスタ、スタックポインタ、プログラムカウンタ、一つの入力ポート、一つの出力ポートを備えています。
### 汎用レジスタ
A,B,C,D,E,Fの六つのレジスタが存在します。各レジスタのビット幅は16bitです。各種計算やデータの保持にお使いいただけます。
### スタックポインタ(SP)
RAM上にあるスタック領域の開始アドレス番号を指し示します。x86系CPUにおけるESP等と同じ役割です。
### プログラムカウンタ(PC)
CPUが現在実行中のアドレスを指し示します。x86系CPUにおけるRIP等と同じ役割です。
### 入力ポート(Input_data)
16bit幅の入力ポートを一つ備えています。
### 出力ポート(Output_data)
16bit幅の出力ポートを一つ備えています。
### RAM
NC-16はアドレス幅16bit、入出力幅16bitのRAMに対応しています。
## ALU
NC-16内部に存在するALU(Arithmetic Logic Unit)は二つの入力、Input1とInput2に対し算術演算を行います。対応している算術演算は次の通りです。
1. 加算
2. 減算
3. 除算（商のみ出力）
4. 乗算
5. AND
6. OR
7. XOR
8. NOT

Input1は下記から選択可能です。ALU Input1 Select and ALU bypassを用いて選択します。
1. Aレジスタ
2. Bレジスタ
3. Cレジスタ
4. Dレジスタ
5. Eレジスタ
6. Fレジスタ
7. SPレジスタ
8. Input_data
9. オペランド

Input2は下記から選択可能です。ALU Input2 Selectを用いて選択します。
1. Aレジスタ
2. Bレジスタ
3. Cレジスタ
4. Dレジスタ
5. Eレジスタ
6. Fレジスタ
7. SPレジスタ
8. オペランド
# NC-16命令セット（Instruction Set Architecture）
## 概要
　NC-16の命令はすべて8バイトの固定長となっています。前半4バイトがオペコード、後半4バイトがオペランドを表します。オペランドを使用しないオペコードの場合、オペランドの値は0で埋めておく必要があります。
1. [32:17]オペコード
2. [16:1]オペランド

## Instruction Decorder仕様
1ビットのInstruction Execute信号と16ビットのオペコードを18ビットのCPU制御信号に変換します。CPU制御信号の仕様は次の通りです。

|bit|意味|
|:--:|:--:|
|[17:13]|ALU Input1 Select and ALU bypass|
|[12:10]|ALU Input2 Select|
|[9:7]|ALU function Select|
|[6:3]|Register Write Enable|
|[2:1]|RAM Address Select|
|[0]|RAM Write Enable
### ALU Input1 Select and ALU bypass
ALUのInput1の選択、Input1をALUに入力せずそのままレジスタの入力側にバイパスするかどうかを決定します。ALU Input1 Select and ALU bypassの仕様は次の通りです。

|bit|意味|
|:--:|:--:|
|[17:14]|ALU Input1 Select|
|[13]|ALU bybass。0b0のときInput1信号はALUをバイパスします。すなわち、ALUを経由せずレジスタ入力側に直接信号が送り込まれます。0b1のときALUにInput1を入力します。|

ALU Input1 Selectの仕様は次の通りです。
|bit17|bit16|bit15|bit14|意味|
|:--:|:--:|:--:|:--:|:--:|
|0|0|0|0|Input1=A register|
|0|0|0|1|Input1=B register|
|0|0|1|0|Input1=C register|
|0|0|1|1|Input1=D register|
|0|1|0|0|Input1=E register|
|0|1|0|1|Input1=F register|
|0|1|1|1|Input1=SP register|
|1|0|0|0|Input1=Input_data|
|1|0|0|1|Input1=オペランド|
|X|X|X|X|禁止|

### ALU Input2 Select
ALUのInput2の選択を行います。仕様は次の通りです。
|bit12|bit11|bit10|意味|
|:--:|:--:|:--:|:--:|
|0|0|0|Input2=A register|
|0|0|1|Input2=B register|
|0|1|0|Input2=C register|
|0|1|1|Input2=D register|
|1|0|0|Input2=E register|
|1|0|1|Input2=F register|
|1|1|0|Input2=SP register|
|1|1|1|Input2=オペランド|
|X|X|X|禁止|
### ALU function select
与えられた二つの入力に対し、どのような算術演算を実行するか選択します。仕様は次の通りです。
bit9|bit8|bit7|意味|
:--:|:--:|:--:|:--:|
|0|0|0|Input1 + Input2|
|0|0|1|Input1 - Input2 ※本演算において負数は2の補数を用いて表現します。|
|0|1|0|Input * Input2|
|0|1|1|Input1 AND Input2|
|1|0|0|Input1 OR Input2|
|1|0|1|NOT Input1|
|1|1|0|Input1 XOR Input2|
|1|1|1|Input1 ÷ Input2
### Register Write Enable
レジスタへの値書き込みを制御します。仕様は次の通りです。
|bit6|bit5|bit4|bit3|意味|
|:--:|:--:|:--:|:--:|:--:|
|0|0|0|0|A register書き込み有効|
|0|0|0|1|B register書き込み有効|
|0|0|1|0|C register書き込み有効|
|0|0|1|1|D register書き込み有効|
|0|1|0|0|E register書き込み有効|
|0|1|0|1|F register書き込み有効|
|0|1|1|1|SP register書き込み有効|
|1|1|1|1|全レジスタ書き込み無効|
|X|X|X|X|禁止|
### RAM Address Select
RAMアドレス端子へどの信号を入力するか選択します。仕様は次の通りです。
|bit2|bit1|意味|
|:--:|:--:|:--:|
|0|0|PC|
|0|1|A register|
|1|0|オペランド|
|1|1|禁止|
### RAM Write Enable
RAM Write Enableが0b1のとき、次のクロック立ち上がりでBレジスタの値をRAM Address Selectで選択された信号のアドレス値に書き込みます。0b0のときは、次のクロック立ち上がりで何もしません。