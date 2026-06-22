# Instruction_Decoder_Specification

## Instruction Decorder仕様
1ビットのInstruction Execute信号、2ビットのFLAGS信号、16ビットのオペコードを19ビットのCPU制御信号に変換します。CPU制御信号の仕様は次の通りです。

|bit|意味|
|:--:|:--:|
|[18]|HALT|
|[17:13]|ALU Input1 Select and ALU bypass|
|[12:10]|ALU Input2 Select|
|[9:7]|ALU function Select|
|[6:3]|Register Write Enable|
|[2:1]|RAM Address Select|
|[0]|RAM Write Enable

Instruction Decorderに入力する信号の仕様は次の通りです。
|bit|意味|
|:--:|:--:|
|[19]|Carry Flag|
|[18]|Zero Flag|
|[17]|Sign Flag|
|[16]|Instruction Execute|
|[15:0]|オペコード

Instruction Execute信号とは命令の実行タイミングを指令する信号です。NC-16の命令長は4バイトです。一方一回のクロックで取得できるデータは2バイト長です。RAM内の命令をすべて取り込むには2クロック必要になります。以上の事情からNC-16は毎クロック命令を実行するわけにはいきませんから、命令実行のタイミングを指令する信号が必要になります。その信号がInstruction Executeです。

### HALT
0b1のときCPU全体のクロックを停止します。0b0のときCPU全体にクロック信号を送ります。
### ALU Input1 Select and ALU bypass
ALUのInput1の選択、Input1をALUに入力せずそのままレジスタの入力側にバイパスするかどうかを決定します。ALU Input1 Select and ALU bypassの仕様は次の通りです。

|bit|意味|
|:--:|:--:|
|[17:14]|ALU Input1 Select|
|[13]|ALU bybass。0b0のときInput1信号はALUをバイパスします。すなわち、ALUを経由せずレジスタ入力側に直接Input1信号が送り込まれます。0b1のときALUにInput1を入力します。|

ALU Input1 Selectの仕様は次の通りです。
|bit17|bit16|bit15|bit14|意味|
|:--:|:--:|:--:|:--:|:--:|
|0|0|0|0|Input1=A register|
|0|0|0|1|Input1=B register|
|0|0|1|0|Input1=C register|
|0|0|1|1|Input1=D register|
|0|1|0|0|Input1=E register|
|0|1|0|1|Input1=BP register|
|0|1|1|0|Input1=SP register|
|0|1|1|1|Input1=オペランド|
|1|0|0|0|Input1=Input_port|
|1|0|0|1|Input1=メモリ|
|1|0|1|0|Input1=PC Register|
|1|0|1|1|Input1=MEMVAL register|
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
|1|0|1|Input2=BP register|
|1|1|0|Input2=SP register|
|1|1|1|Input2=オペランド|
|X|X|X|禁止|
### ALU function select
与えられた二つの入力に対し、どのような算術演算を実行するか選択します。仕様は次の通りです。
bit9|bit8|bit7|意味|
:--:|:--:|:--:|:--:|
|0|0|0|Input1 + Input2|
|0|0|1|Input1 - Input2 ※本演算において負数は2の補数を用いて表現します。|
|0|1|0|Input1 * Input2|
|0|1|1|Input1 AND Input2|
|1|0|0|Input1 OR Input2|
|1|0|1|NOT Input1|
|1|1|0|Input1 XOR Input2|
|1|1|1|Input1をInput2ビットだけ右シフト
### Register Write Enable
レジスタへの値書き込みを制御します。仕様は次の通りです。
|bit6|bit5|bit4|bit3|意味|
|:--:|:--:|:--:|:--:|:--:|
|0|0|0|0|A register書き込み有効|
|0|0|0|1|B register書き込み有効|
|0|0|1|0|C register書き込み有効|
|0|0|1|1|D register書き込み有効|
|0|1|0|0|E register書き込み有効|
|0|1|0|1|BP register書き込み有効|
|0|1|1|0|SP register書き込み有効|
|0|1|1|1|PC register書き込み有効|
|1|0|0|0|Output_port書き込み有効|
|1|0|0|1|MEMADDR書き込み有効|
|1|0|1|0|MEMVAL書き込み有効|
|1|1|1|1|全レジスタ書き込み無効|
|X|X|X|X|禁止|
### RAM Address Select
RAMアドレス端子へどの信号を入力するか選択します。仕様は次の通りです。
|bit2|bit1|意味|
|:--:|:--:|:--:|
|0|0|PC|
|0|1|MEMADDR register + opd|
|1|0|オペランド|
|1|1|禁止|
### RAM Write Enable
RAM Write Enableが0b1のとき、次のクロック立ち上がりでBレジスタの値をRAM Address Selectで選択された信号のアドレス値に書き込みます。0b0のときは、次のクロック立ち上がりで何もしません。