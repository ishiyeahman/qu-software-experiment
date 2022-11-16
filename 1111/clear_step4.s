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
		jsr Init_Q

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
		*lea.l uart1_interrupt, %a0
		*move.l %a0, 0x110 /* STEP2.1 level 4, (64+4)*4 割り込み処理ルーチンの開始アドレスをレベル4割り込みベクタに設定 */




		move.l #uart1_interrupt, 0x110
		move.w #0xe108, USTCNT1 |受信割り込み許可、送信割り込み無効 /* STEP2.2 */
		move.l #0x00ff3ffb,IMR  |受信割り込みマスク /* STEP2.3 */
		move.w #0x2000, %SR    /* STEP2.4 割り込み許可．(スーパーバイザモードの場合) 走行レベル0 */

		bra MAIN

		***************************************************************
		** 現段階での初期化ルーチンの正常動作を確認するため，最後に’a’を
		** 送信レジスタUTX1に書き込む．'a'が出力されれば，OK.
		***************************************************************
		.section .text
		.even




	
MAIN:
		*move.w #0x0800+'a', UTX1 | 0x0800を足す理由については，|付録参照



		jsr TEST_READY
		
LOOP:
		bra LOOP

/*以下テスト*/
TEST_READY:
	
		move.w #16, %d4
		move.w #16, %d5
		move.b #0x61, %d1
		bra TEST_LOOP

TEST_LOOP2:

		addq #1, %d1
		move.w #16, %d4

TEST_LOOP:
		move.l #0, %d0
		jsr INQ
		subq #1, %d4
		bne TEST_LOOP
		subq #1, %d5
		beq TEST_END
		bra TEST_LOOP2

TEST_END:
		rts
/*以上テスト*/

uart1_interrupt:
		movem.l %d0, -(%sp)



		move.w UTX1, %d0	/*step4:UTX1のコピー*/
		
		move.l #0, %d1	/*chの選択*/

		cmp.w #0x8000,%d0
		bcc INTERPUT

INTERPUT_RTE:
		movem.l (%sp)+, %d0

		rte


INTERPUT:
	move.l #1, %d1

	move.w #0x2700, %SR	/*step4.1:走行レベル7*/
	
	cmp.l #0x0, %d1		/*step4.2:ch!=0で分岐*/

	bne INTERPUT_END

	move.l #1, %d0
	jsr OUTQ		/*step4.3:OUTQの実行*/

	cmp.l #0, %d0		/*step4.4:戻り値が0で分岐*/
	beq INTERPUT_MASK

	move.b #'a', %d1
	addi.w #0x0800, %d1
	move.w %d1, UTX1	/*step4.5:ヘッダ付与*/


INTERPUT_END:
	jmp INTERPUT_RTE

INTERPUT_MASK:
	
	move.l #0xff3ffb, IMR	/*step4.4:送信割り込みのマスク : 割り込み選択レジスタを書き換える*/

	move.b #'Z', %d1
	addi.w #0x0800, %d1
	move.w %d1, UTX1


	bra INTERPUT_END


*******************************************************
** 						QUEUE (TA)
*******************************************************


.section .data
.equ TOP, 0
.equ BOTTOM, 4
.equ IN, 8
.equ OUT, 12
.equ S, 16
.equ DATA_TOP, 18
.equ DATA_LEN, 256
.equ QUEUE_SIZE, DATA_TOP + DATA_LEN /* 18 + 256 = 274 */

QUEUE_TOP: ds.b QUEUE_SIZE * 2

/* 初期化 */
********************
* 初期化
********************

Init_Q:
    movem.l %d0-%d1/%a0-%a2, -(%sp) /* 使用レジスタの退避 */

    move.l #0, %d0 /* キュー番号 = 0 */

Init_Q_sub:
    lea.l QUEUE_TOP, %a0 /* キューの先頭アドレス */
    move.l %d0, %d1
    mulu.w QUEUE_SIZE, %d1 /* キューnの相対先頭アドレス = n * (キューサイズ) */
    add.l %d1, %a0 /* a0 = キューnの先頭アドレス */
    lea.l DATA_TOP(%a0), %a1 /* a1 = キューnのデータ領域先頭アドレス = DATA_TOP + a0 */
    move.l %a1, TOP(%a0) /* キューnのTOPのアドレス = a0 + TOP であるのでそこにa1を格納 */
    move.l %a1, IN(%a0) /* キューnのINのアドレスにa1を格納 */
    move.l %a1, OUT(%a0) /* キューnのOUTのアドレスにa1を格納 */
    lea.l BOTTOM(%a0), %a1 /* a1 = キューnのBOTTOMのアドレス */
    lea.l QUEUE_SIZE-1(%a0), %a1 /* a1 == BOTTOM = キューnの終端アドレス */
    move.w #0, S(%a0) /* データ数 = 0 */
    addq.l #1, %d0 /* キュー番号++ */
    cmpi.l #2, %d0 /* キューの個数分(2)ループ */
    bne Init_Q_sub

    movem.l (%sp)+, %d0-%d1/%a0-%a2 /* 使用レジスタの復帰 */
    rts


*****************
** INQ
*****************

**************************************
**入力
**  d0:キューの選択 [long]
**  d1:書き込むデータ [long]
**出力
**  d0:成功(1)or失敗(0) [long]
**************************************
INQ:

    /* 現走行レベルの退避 */
    move.w %SR, -(%sp)

    /* 割り込み禁止 */
    move.w #0x2700, %SR

    movem.l %a0-%a1, -(%sp)
    lea.l QUEUE_TOP, %a0 /* a0 = キュー0の先頭アドレス */
    mulu.w QUEUE_SIZE, %d0 /* キューnの相対先頭アドレス = n * (キューサイズ) */
    add.l %d0, %a0 /* a0 = キューnの先頭アドレス */

    cmpi.w #256, S(%a0)
    bne INQ_1

    /* S == 256のときd0 = 0(失敗) としてENDへ */
    move.l #0, %d0
    bra INQ_END

INQ_1:
    movea.l IN(%a0), %a1 /* a1 = in */
    move.b %d1, (%a1) /* q[in] = d1 */ 

    cmpa.l BOTTOM(%a0), %a1 /* in == bottom かを判定 */
    bne INQ_ELSE

    /* in == bottom のとき*/
    move.l TOP(%a0), IN(%a0) /* in = top */
    bra INQ_2

/* in != bottom のとき*/
INQ_ELSE:
    addq.l #1, %a1 /* a1++ */
    move.l %a1, IN(%a0) /* in = a1 */

/* s++, d0 = 1(成功) としてENDへ */
INQ_2:
    addq.w #1, S(%a0)
    move.l #1, %d0

/* 使用レジスタの復帰 */
INQ_END:
    movem.l (%sp)+, %a0-%a1 
    move.w (%sp)+, %SR
    rts


*****************
* OUTQ
*****************

**********************************************
**入力
**  d0:キューの選択  [long]

**出力
**  d0:成功(1)or失敗(0) [long]
**  d1:取り組んだデータ [byte]
**********************************************
OUTQ:
    /* 現走行レベルの退避 */
    move.w %SR, -(%sp)

    /* 割り込み禁止 */
    move.w #0x2700, %SR

    movem.l %a0-%a1, -(%sp)
    lea.l QUEUE_TOP, %a0 /* a0 = キュー0の先頭アドレス */
    mulu.w QUEUE_SIZE, %d0 /* キューnの相対先頭アドレス = n * (キューサイズ) */
    add.l %d0, %a0 /* a0 = キューnの先頭アドレス */

    cmpi.w #0, S(%a0)
    bne OUTQ_1

    /* S == 0のときd0 = 0(失敗) としてENDへ */
    move.l #0, %d0
    bra OUTQ_END

OUTQ_1:
    movea.l OUT(%a0), %a1 /* a1 = out */
    move.b (%a1), %d1 /* d1 = q[out] */

    cmpa.l BOTTOM(%a0), %a1 /* out == bottom かを判定 */
    bne OUTQ_ELSE

    /* out == bottom のとき*/
    move.l TOP(%a0), OUT(%a0) /* out = top */
    bra OUTQ_2

/* out != bottom のとき*/
OUTQ_ELSE:
    addq.l #1, %a1 /* a1++ */
    move.l %a1, OUT(%a0) /* out = a1 */

/* s--, d0 = 1(成功) としてENDへ */
OUTQ_2:
    subq.w #1, S(%a0)
    move.l #1, %d0

/* 使用レジスタの復帰 */
OUTQ_END:
    movem.l (%sp)+, %a0-%a1 
    move.w (%sp)+, %SR
    rts







