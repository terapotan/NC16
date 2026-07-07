# Instruction_Decoder_Specification
## 命令実行までの過程
　本節ではRAMに格納された命令がCPUによって読みだされ実行されるまでの過程について解説します。

　現状のNC-16には、他市販CPUで見られるようなパイプライン実行、Out of Order実行等の高速化のための機構は搭載されていません。命令フェッチ、命令解釈、命令実行の各手順をメモリに記載されている順番通りに行うだけです。

　CPUの制御はCPU Control BUSを用いて行われます。CPU Control BUSに、CPUに行わせたい処理に応じた信号を出力した状態でクロックを立ち上げると所定の処理が行われます。命令デコーダ部はメモリから読み取った命令種別に応じて、適切なタイミングで適切な信号をCPU Control BUSに流す役割を負っています。

　命令デコードは複数の"ステージ"に分割されます。ステージとは命令デコードの段階を表す用語です。命令デコードにおいては、ある段階ではRAMから命令をロードする、ある段階では命令を実行する、のように段階ごとに実行すべき事柄は変わります。ハードウェアロジックでこれらの処理を直接組もうとすると回路が大変複雑になりますから、「今どのステージを実行しているのか」を表す値を別途持っておいて、その値に応じて各部の処理が変化するようにしています。

　ステージの実体は8bitの符号なし整数です。処理が進むごとに0ステージ目、1ステージ目……のように1ずつカウントアップしていきます。ステージはクロックが立ち上がる時カウントアップします。ステージの値はIDSCで管理しています。

　一つの機械語には複数のマイクロコードが対応します（一つのマイクロコードが対応する場合もあります）。マイクロコードとはCPUの処理を機械語よりも細かい単位で記述したものであり、NC-16ではCPU Control BUS信号の羅列を指します（厳密には異なる。詳細は後述）。マイクロコードはMicrocode ROMに格納されています。どの機械語にどのマイクロコードを対応させるか、すなわちどの機械語に該当のマイクロコードが格納されているベースアドレスを対応させるか、といった対応付けはIMBDで行われています。

　命令は次の手順で実行されます。
1. 0ステージ目：RAMからIRへオペコードを転送する。
2. 1ステージ目：RAMからIRへオペランドを転送する。
3. 2ステージ目：
   1. IMBDにオペコードを入力し、機械語に対応するマイクロコードが格納されているメモリアドレスをMicrocode ROMに入力する。2ステージ目終了時、Microcode ROMに格納されているマイクロコードが実行される。マイクロコードの終端ステージ数もこのステージで併せて出力する。終端ステージ数とは、指定したベースアドレスから何個のマイクロコードが格納されているかを表す値である。末尾のマイクロコードの次のマイクロコードが実行された時点におけるステージ数を出力する。例えば一つの機械語に対し2つのマイクロコードが対応している場合、終端ステージ数は1+2+1=5となる。
   2. 2ステージ目以降のステージでは、IDSCのリセットによって0ステージ目に復帰するまで、PCとIRへのクロック供給を停止する。
4. 3ステージ目以降：Microcode ROMに格納されているマイクロコードを実行する。終端ステージ数に達した場合は、IDSCに次のクロックでIRNRの値をロードするよう指令する信号を送出し、所定のステージに戻る。実行フェーズは終了し命令フェッチのフェーズに戻る。

## 各部解説
　命令デコードに関わる部品を解説します。
### Instruction Register(IR)
　メモリから読みだした命令を格納するレジスタです。実体は16bit X 2のシフトレジスタです。
### Instruction Microcode Base-address Decoder(IMBD)
　オペコードに対応するマイクロコードが格納されているアドレスを、IRから与えられたオペコードを元に算出します。
### Instruction Decode Stage Counter(IDSC)
　命令デコードのステージ数をカウントします。
### Instruction Terminate Stage Decoder(ITSD)
　オペコードに対応した終端ステージ数を出力します。
### IDSC Reset Number Register(IRNR)
　終端ステージに達したときにIDSCにロードする値を保持するレジスタです。
### Instruciton IDSC Reset Number Decoder(IIRND)
　オペコードに対応するIDSC Reset Numberを出力します。
### Terminate Stage Register
　現在の終端ステージ数を格納します。
### Microcode ROM
　マイクロコードが格納されているROMです。
### Microcode Operand Register(MOR)
　マイクロコード実行時にオペランドとして使用するレジスタです。マイクロコード実行時、機械語で与えられたオペランド（IRに格納されたオペランド）以外に、別の値を命令のオペランドとして指定したいときがあります。例えば機械語で与えられたオペランドに3を加算する場合、3という値をどこかで抱え持っておく必要があります。レジスタ、ALU側に与えるオペランドとしてIRに格納されたオペランドを指定するか、MORのオペランドを指定するかは、マイクロコードで選択できるようになっています。

## Microcode仕様
|bit|意味|
|:--:|:--:|
[23:22]|未使用
[21]|MOR write enable
[20]|IR operand or MOR operand select
[19:0]|CPU Control BUS

> Microcodeのビット数を変更する場合は、ROMデータジェネレータの都合上、8の倍数ビットにしなければならない。ファイルの読み書きがバイト単位でしか行えないためである。

### MOR write enable
　MOR write enableが0b1のとき、該当のワードの下位16ビットをMORに書き込みます。このときCPU Control BUSにはnop相当の信号が出力されます。0b0のとき該当ワードの下位20ビットをCPU Control BUSに出力します。
### IR operand or MOR operand select
　Instruction Decoderから出力するオペランドを、IRに格納されているオペランドとするか、MORに格納されているオペランドとするか選択できます。0b0のときIRに格納されているオペランドを、0b1のときMORに格納されているオペランドを出力します。

## CPU Control BUS
1ビットのInstruction Execute信号、2ビットのFLAGS信号、16ビットのオペコードを20ビットのCPU制御信号に変換します。CPU制御信号（CPU Control Bus）の仕様は次の通りです。

|bit|意味|
|:--:|:--:|
|[19]|flag_write_sw|
|[18]|HALT|
|[17:13]|ALU Input1 Select and ALU bypass|
|[12:10]|ALU Input2 Select|
|[9:7]|ALU function Select|
|[6:3]|Register Write Enable|
|[2:1]|RAM Address Select|
|[0]|RAM Write Enable

IMBDに入力する信号の仕様は次の通りです。
|bit|意味|
|:--:|:--:|
|[19]|Carry Flag|
|[18]|Zero Flag|
|[17]|Sign Flag|
|[16]|Instruction Execute|
|[15:0]|オペコード

Instruction Execute信号とは命令の実行タイミングを指令する信号です。NC-16の命令長は4バイトです。一方一回のクロックで取得できるデータは2バイト長です。RAM内の命令をすべて取り込むには2クロック必要になります。以上の事情からNC-16は毎クロック命令を実行するわけにはいきませんから、命令実行のタイミングを指令する信号が必要になります。その信号がInstruction Executeです。

### flag_write_sw
　FLAGSレジスタへ入力する信号を切り替えます。0b0のときレジスタの入力バスに流れている信号をFLAGSレジスタへ入力します。0b1のときALUからのCarry Flag,Zero Flag,Sign Flagの値をFLAGSレジスタへ入力します（それ以外のビットは保持します）。0b0の時はRegister Write EnableをFLAGSレジスタにセットしないとFLAGSレジスタへの書き込みは行われませんが、0b1の時はRegister Write Enableの指定に関係なく、ALUからFLAGSレジスタへのCarry,Zero,Sign Flag信号の書き込みを必ず行います。もちろんRegister Write Enableで指定したレジスタへの書き込みも併せて行われます。
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
|1|1|0|0|Input1=FLAGS register|
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
|1|0|1|1|FLAGS書き込み有効|
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