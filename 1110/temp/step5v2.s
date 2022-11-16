		***************************************************************
		**各種レジスタ定義
		***************************************************************

		***************
		** レジスタ群の先頭
		***************
		.equ REGBASE,   0xFFF000          | DMAPを使用．
		.equ IOBASE,    0x00d00000

		***************
		** 割り込み関係のレジスタ
		***************
		.equ IVR,       REGBASE+0x300     |割り込みベクタレジスタ
		.equ IMR,       REGBASE+0x304     |割り込みマスクレジスタ
		.equ ISR,       REGBASE+0x30c     |割り込みステータスレジスタ
		.equ IPR,       REGBASE+0x310     |割り込みペンディングレジスタ

		***************
		** タイマ関係のレジスタ
		***************
		.equ TCTL1,     REGBASE+0x600     |タイマ１コントロールレジスタ
		.equ TPRER1,    REGBASE+0x602     |タイマ１プリスケーラレジスタ
		.equ TCMP1,     REGBASE+0x604     |タイマ１コンペアレジスタ
		.equ TCN1,      REGBASE+0x608     |タイマ１カウンタレジスタ
		.equ TSTAT1,    REGBASE+0x60a     |タイマ１ステータスレジスタ

		***************
		** UART1（送受信）関係のレジスタ
		***************
		.equ USTCNT1,   REGBASE+0x900     | UART1ステータス/コントロールレジスタ
		.equ UBAUD1,    REGBASE+0x902     | UART1ボーコントロールレジスタ
		.equ URX1,      REGBASE+0x904     | UART1受信レジスタ
		.equ UTX1,      REGBASE+0x906     | UART1送信レジスタ

		***************
		** LED
		***************
		.equ LED7,      IOBASE+0x000002f  |ボード搭載のLED用レジスタ
		.equ LED6,      IOBASE+0x000002d  |使用法については付録A.4.3.1
		.equ LED5,      IOBASE+0x000002b
		.equ LED4,      IOBASE+0x0000029
		.equ LED3,      IOBASE+0x000003f
		.equ LED2,      IOBASE+0x000003d
		.equ LED1,      IOBASE+0x000003b
		.equ LED0,      IOBASE+0x0000039

		***************************************************************
		** スタック領域の確保
		***************************************************************
		.section .bss
		.even
SYS_STK:
		.ds.b   0x4000  |システムスタック領域
		.even
SYS_STK_TOP:            |システムスタック領域の最後尾

		***************************************************************
		** 初期化
		** 内部デバイスレジスタには特定の値が設定されている．
		** その理由を知るには，付録Bにある各レジスタの仕様を参照すること．
		***************************************************************

.section .text
		.even
boot:
		* スーパーバイザ&各種設定を行っている最中の割込禁止
		move.w #0x2700,%SR
		lea.l  SYS_STK_TOP, %SP | Set SSP

		****************
		**割り込みコントローラの初期化
		****************
		move.b #0x40, IVR       |ユーザ割り込みベクタ番号を| 0x40+levelに設定．
		move.l #0x00ffffff,IMR  |全割り込みマスク /* STEP2.3 */

		****************
		** 送受信(UART1)関係の初期化(割り込みレベルは4に固定されている)
		****************
		move.w #0x0000, USTCNT1 |リセット
		move.w #0xe100, USTCNT1 |送受信可能,パリティなし, 1 stop, 8 bit,|送受割り込み禁止
		move.w #0x0038, UBAUD1  |baud rate = 230400 bps

		****************
		** タイマ関係の初期化(割り込みレベルは6に固定されている)
		*****************
		move.w #0x0004, TCTL1   | restart,割り込み不可,|システムクロックの1/16を単位として計時，|タイマ使用停止

		***************************************************************
		** STEP2の処理
		***************************************************************
		/* 初期化処理をメインルーチンからこちらへ移動 */
		*lea.l uart1_interrupt, %a0
		*move.l %a0, 0x110 /* STEP2.1 level 4, (64+4)*4 割り込み処理ルーチンの開始アドレスをレベル4割り込みベクタに設定 */
		move.l #uart1_interrupt, 0x110
		move.w #0xe100, USTCNT1 |送受信割り込みマスク
		move.l #0x00ff3ffb,IMR  |UART1許可
		move.w #0x2700, %SR    /* 走行レベル7 */
		

		bra MAIN

		***************************************************************
		** 現段階での初期化ルーチンの正常動作を確認するため，最後に’a’を
		** 送信レジスタUTX1に書き込む．'a'が出力されれば，OK.
		***************************************************************
		.section .text
		.even



.section .data
	TDATA1: .ascii "0123456789ABCDEF"
	TDATA2: .ascii "klmnopqrstuvwxyz"	



	
MAIN:
		jsr Init_Q
		move.b #'1', LED7
		move.w #0xe108,USTCNT1
		move.w #0x2000, %SR    /* 走行レベル0 */


PS_TEST1:
		/* jsr PUTSTRING(0, #TDATA1, 16)*/
		move.l	#0x00, %d1
		move.l	#TDATA1, %d2
		move.l	#0x10, %d3
		jsr PUTSTRING
		
	
		move.b #'2', LED6
		move.l	#0x000fff, %d4
	
		
LOOP:
		subq.l #1,%d4
		beq PS_TEST2
		move.b #'5', LED3
		
		bra LOOP

PS_TEST2:
		move.b #'6', LED2
		move.l	#0x00, %d1
		move.l	#TDATA2, %d2
		move.l	#0x10, %d3
		jsr PUTSTRING
		bra PS_TEST2

/*以下テスト*/
TEST_READY:
		*movem.l %d1-%d5, -(%sp)
	
		move.w #16, %d4
		move.w #16, %d5
		move.b #0x61, %d1
		bra TEST_LOOP

TEST_LOOP2:

		addq #1, %d1
		move.w #16, %d4

TEST_LOOP:
		moveq #1, %d0
		*move.w #0x1000, %d0
		jsr INQ
		*jsr OUTQ
		subq #1, %d4
		bne TEST_LOOP
		subq #1, %d5
		beq TEST_END
		bra TEST_LOOP2

TEST_END:
		*movem.l (%sp)+, %d1-%d5
		rts
/*以上テスト*/

uart1_interrupt:
		move.b #'3', LED5
		movem.l %d0, -(%sp)

		*move.b #'a', %d0 /* URX1の下位8ビットのデータを転送 */
		*addi.w #0x0800, %d0 /* 即値をレジスタd0に加算 */
		*move.w %d0, UTX1 /* 16ビットのデータをUTX1に転送 */


		move.w UTX1, %d0	/*step4:UTX1のコピー*/
		
		move.b #0, %d1	/*chの選択*/

		cmp #0x8000,%d0
		bcc INTERPUT

		movem.l (%sp)+, %d0
		
		rte


INTERPUT:
		movem.l %d0-%d2, -(%sp)

		move.w #0x2700, %SR	/*step4.1:走行レベル7*/

		cmp.b #0x0, %d1		/*step4.2:ch!=0で分岐*/

		bne INTERPUT_END

		move.b #1, %d0

		jsr OUTQ		/*step4.3:OUTQの実行*/

		cmp.w #0, %d0		/*step4.4:戻り値が0で分岐*/

		beq INTERPUT_MASK

		move.b %d1, %d2

		addi.w #0x0800, %d2


		move.w %d2, UTX1	/*step4.5:ヘッダ付与*/


INTERPUT_END:
		movem.l (%sp)+, %d0-%d2

		*movem.l (%sp)+, %d0

		rte

INTERPUT_MASK:
		move.w #0xe100, USTCNT1	/*step4.4:送信割り込みのマスク*/
		/* ↑ 何故かコメントアウトされていたので、修正 */

		bra INTERPUT_END

*************************************************************
**PUTSTRING
**入力
**d1:チャネル
**d2:データ読み込み先の先頭アドレス
**d3:送信するデータ数size
**戻り値
**d0:実際に送信したデータ数
*************************************************************
PUTSTRING:
		movem.l %a0-%a6/%d1-%d6, -(%SP)

		cmp.b #0x00, %d1		/*ch!=0で分岐*/
		bne PUTSTRING_END
		/* rv: バイトサイズの比較。０ではないときに終了する*/

		move.w #0x0000,%d4 		/*%d4=sz:送信したデータ数を格納*/
		/* rv: データ数(sz)の初期化*/

		move.l %d2,%a1 		/*%d5:データの読み込み先アドレス/
		/* rv: 読み込み先の先頭アドレスをa1に格納する*/	

		cmp.w #0x0000,%d3		/*size=0で分岐*/
		beq PUTSTRING_END
		/* rv: d3(size)が0ならば終了する*/


LOOP_STEP5:
		cmp.w %d4,%d3		/*sz=sizeで分岐*/
		beq PUTSTRING_MASK
		/* d3 と d4 size = sz ならばマスクへ移動*/

		move.l #0x01,%d0 		/*キュー番号の設定*/
		move.b (%a1)+,%d1	/*データをINQの入力d1に格納*/
		/* rv: 先頭アドレスから順に格納する*/

		jsr INQ

		cmp.l #0x00,%d0		/*成功or失敗判定*/
		beq PUTSTRING_MASK
		/*rv : 失敗ならばマスクへ移動する*/

		addq.w #0x01,%d4		/*sz++*/
		bra LOOP_STEP5

PUTSTRING_MASK:
		move.b #'4', LED4



		move.w #0xe10c, USTCNT1	/*送信割り込み許可*/
		bra PUTSTRING_END

PUTSTRING_END:
		move.w %d4,%d0		/*戻り値d0に実際に送信したデータ数を格納*/
		movem.l (%SP)+, %a0-%a6/%d1-%d6

		*rte 			/*?*/
		/* bus error出たので変更した*/

		***
		***
		rts

******************************************************************************:

******
******以降QUEUE
******
.section .data
******************************
** キュー用のメモリ領域確保 ↓↓
******************************
.equ B_SIZE, 256
.equ ALL_B_SIZE, B_SIZE + B_SIZE |受信と送信で１本ずつ|

top: .ds.b ALL_B_SIZE-1 |キューのデータ領域|
bottom: .ds.b 1
in: .ds.l 2 |キューの各種ポインタ↓|
out: .ds.l 2
PUT_FLG: .ds.b 2
GET_FLG: .ds.b 2
s: .ds.l 2

top_ptr: .ds.l 1 |実行時用一時保存領域↓|
bottom_ptr: .ds.l 1
in_ptr: .ds.l 1
out_ptr: .ds.l 1
PUT_FLG_ptr: .ds.b 1
GET_FLG_ptr: .ds.b 1
s_ptr: .ds.l 1

.even



.section .text
******************************
** キュー用のメモリ領域確保 ↑↑
******************************

**********************  

** キューの初期化処理↓↓  

**********************  

Init_Q: 

 	movem.l	%d0/%a0-%a4, -(%sp) 

  

	move.l	#2, %d0			/*#4 -> #2*/ 

  

	lea.l 	top, %a0 

 	lea.l	in, %a1 

 	lea.l	out, %a2 

 	lea.l	PUT_FLG, %a3 

 	lea.l	GET_FLG, %a4 

  

Loop_Init:	 

 	move.l 	%a0, (%a1)+ 

 	move.l 	%a0, (%a2)+ 

 	move.b 	#0x01, (%a3)+ 

 	move.b 	#0x00, (%a4)+ 

  

	adda.l	#B_SIZE, %a0 

  

	subq.l	#1, %d0 

 	bhi	Loop_Init 

  

	movem.l	(%sp)+, %d0/%a0-%a4 

 	rts 

 **********************  

** キューの初期化処理 ↑↑ 

 **********************  

 

 

***********************************  

** INQ キューへのデータ書き込み↓↓ 

 ** a0: 書き込むデータのアドレス  

** (入力)d0: 書き込むキューの番号0~1		 

 ** (出力)d0: 結果(00:失敗, 01:成功)  

*********************************** 

 INQ: 

 	movem.l	%d1-%d6/%a0-%a6, -(%sp)		/*現走行レベルの退避*/ 

 	move.w	%SR, -(%sp) 

 	move.w	#0x2700, %SR			/*割り込み禁止*/ 

 		 

	move.l	%d0, %d3		/*キュー番号の保存*/ 

  

	lea.l	PUT_FLG, %a4 

 	add.l	%d0, %a4 

 	move.b	(%a4), PUT_FLG_ptr 

  

	lea.l	GET_FLG, %a4 

 	add.l	%d0, %a4 

 	move.b	(%a4), GET_FLG_ptr 

  

	mulu	#4, %d0			 

 	lea.l	in, %a4 

 	add.l	%d0, %a4 

 	move.l	(%a4), in_ptr 

  

	lea.l	out, %a4 

 	add.l	%d0, %a4 

 	move.l	(%a4), out_ptr 

  

	mulu	#64, %d0 

 	lea.l 	top, %a4 

 	add.l	%d0, %a4 

 	move.l	%a4, top_ptr 

  

	move.l	#256, %d2		/*#768 -> #256*/ 

 	sub.l	%d0, %d2 

 	move.l	#0, %d0			/*d0初期化*/	 

 	lea.l	bottom, %a4 

 	sub.l	%d2, %a4 

 	move.l	%a4, bottom_ptr 

  

	jsr 	PUT_BUF 	/* キューへの書き込み */ 

  

	lea.l	PUT_FLG, %a4 

 	add.l	%d3, %a4	 

 	move.b 	PUT_FLG_ptr,(%a4)	 

  

	lea.l	GET_FLG, %a4 

 	add.l	%d3, %a4	 

 	move.b 	GET_FLG_ptr,(%a4)	 

  

 

	mulu	#4, %d3 

 	lea.l 	in, %a4 

 	add.l	%d3, %a4 

 	move.l	in_ptr, (%a4) 

  

	lea.l	out, %a4 

 	add.l	%d3, %a4 

 	move.l	out_ptr, (%a4) 

  

	move.w	(%sp)+, %SR 

 	movem.l	(%sp)+, %d1-%d6/%a0-%a6		/*旧走行レベルの回復*/ 

 	rts 

 ***********************************  

** INQ キューへのデータ書き込み↑↑ 

 *********************************** 

  

 

****************************************  

** PUT_BUF↓↓ 

 ** a0: 書き込むデータのアドレス 

 ** d0: 結果(00:失敗, 00以外:成功)  

** d1: 書き込む8bitデータ 

 ****************************************  

PUT_BUF: 

 	movem.l	%a1-%a3, -(%sp) 

 	move.b	PUT_FLG_ptr, %d0 

  

	cmp.b	#0x00, %d0		/* PUT不可能(失敗) */ 

 	beq	PUT_BUF_Finish 

  

	movea.l	in_ptr, %a1		/* キューにデータを挿入 */ 

 	move.b	%d1, (%a1)+ 

  

	addi.l	#1, s			/* キュー内のデータ数:+1 */ 

  

	move.l	bottom_ptr, %a3		/* a3はキュー末尾 */ 

 	cmpa.l	%a3, %a1		/* PUTポインタが末尾を超えた */ 

 	bls	PUT_BUF_STEP1	 

  

	move.l	top_ptr, %a2	/* PUTポインタを先頭に戻す */ 

 	movea.l	%a2, %a1 

  

PUT_BUF_STEP1: 

 	move.l	%a1, in_ptr 

  

	cmpa.l	out_ptr, %a1	/* PUTポインタがGETポインタに追いついた */ 

 	bne	PUT_BUF_STEP2 

  

	move.b	#0x00, PUT_FLG_ptr	/* 満タンなのでPUT不可能(フラグ) */ 

  

PUT_BUF_STEP2: 

 	move.b	#0x01, GET_FLG_ptr 

  

PUT_BUF_Finish: 

 	movem.l	(%sp)+, %a1-%a3 

 	rts 

 ****************************************  

** PUT_BUF↑↑ 

 **************************************** 

 

 

***********************************  

** OUTQ キューからの読み出し↓↓ 

 ** a2: 読み出し先アドレス 

 ** d0(入力):キュー番号 

 ** d0(出力): 結果(00:失敗, 01:成功)  

** d1: 取り出した8bitデータ 

 *********************************** 

 OUTQ: 

 	movem.l	%d2-%d6/%a0-%a6, -(%sp) 

 	move.w	%SR, -(%sp)		/*現走行レベルの退避*/ 

 	move.w	#0x2700, %SR			/*割り込み禁止*/ 

  

	move.l	%d0, %d3		/*キュー番号の保存*/ 

  

	lea.l	PUT_FLG, %a4 

 	add.l	%d0, %a4 

 	move.b	(%a4), PUT_FLG_ptr 

  

	lea.l	GET_FLG, %a4 

 	add.l	%d0, %a4 

 	move.b	(%a4), GET_FLG_ptr 

  

	mulu	#4, %d0			 

 	lea.l	in, %a4 

 	add.l	%d0, %a4 

 	move.l	(%a4), in_ptr 

  

	lea.l	out, %a4 

 	add.l	%d0, %a4 

 	move.l	(%a4), out_ptr 

  

	mulu	#64, %d0 

 	lea.l 	top, %a4 

 	add.l	%d0, %a4 

 	move.l	%a4, top_ptr 

  

	move.l	#256, %d2		/*#768 -> #256*/ 

 	sub.l	%d0, %d2 

 	move.l	#0, %d0			/*d0初期化*/	 

 	lea.l	bottom, %a4 

 	sub.l	%d2, %a4 

 	move.l	%a4, bottom_ptr 

  

	jsr 	GET_BUF 	/* キューからの読み出し */ 

  

	lea.l	PUT_FLG, %a4 

 	add.l	%d3, %a4	 

 	move.b 	PUT_FLG_ptr,(%a4)	 

  

	lea.l	GET_FLG, %a4 

 	add.l	%d3, %a4	 

 	move.b 	GET_FLG_ptr,(%a4)	 

  

 

	mulu	#4, %d3 

 	lea.l 	in, %a4 

 	add.l	%d3, %a4 

 	move.l	in_ptr, (%a4) 

  

	lea.l	out, %a4 

 	add.l	%d3, %a4 

 	move.l	out_ptr, (%a4) 

  

 

	move.w	(%sp)+, %SR		/*旧走行状態の回復*/ 

 	movem.l	(%sp)+, %d2-%d6/%a0-%a6 

 	rts 

 ***********************************  

** OUTQ キューからの読み出し↑↑ 

 *********************************** 

  

 

****************************************  

** GET_BUF↓↓ 

 ** a2: 読み出し先アドレス 

 ** d0: 結果(00:失敗, 00以外:成功)  

** d1: 取り出した8bitデータ 

 ****************************************  

GET_BUF: 

 	movem.l	%a1/%a3-%a4, -(%sp) 

 	move.b	GET_FLG_ptr, %d0 

  

	cmp.b	#0x00, %d0	/* GET不可能(失敗) */ 

 	beq	GET_BUF_Finish 

  

	movea.l	out_ptr, %a1	/* キューからデータを読み出す */ 

 	move.b	(%a1)+, %d1	/* 取り出したデータ */ 

  

 

	subi.l	#1, s		/* キュー内のデータ数:-1 */ 

  

	move.l	bottom_ptr, %a3	/* a3はキュー末尾 */ 

 	cmpa.l	%a3, %a1	/* GETポインタが末尾を超えた */ 

 	bls	GET_BUF_STEP1	 

  

	move.l	top_ptr, %a4	/* GETポインタを先頭に戻す */ 

 	movea.l	%a4, %a1 

  

GET_BUF_STEP1: 

 	move.l	%a1, out_ptr 

  

	cmpa.l	in_ptr, %a1	/* GETポインタがPUTポインタに追いついた */ 

 	bne	GET_BUF_STEP2 

  

	move.b	#0x00, GET_FLG_ptr	/* データがないのでGET不可能(フラグ) */ 

  

GET_BUF_STEP2: 

 	move.b	#0x01, PUT_FLG_ptr 

  

GET_BUF_Finish: 

 	movem.l	(%sp)+, %a1/%a3-%a4 

 	rts 

 ****************************************  

** GET_BUF↑↑ 

 **************************************** 

 

