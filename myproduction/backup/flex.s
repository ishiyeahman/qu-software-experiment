/* 初期化*/

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
		WORK: .ds.b 256 /*step6_test*/
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
		move.w #0xe108, USTCNT1 |送受信可能,パリティなし, 1 stop, 8 bit,|送受割り込み禁止		
		move.w #0x0038, UBAUD1  |baud rate = 230400 bps

		****************
		** タイマ関係の初期化(割り込みレベルは6に固定されている)
		****************
		move.w #0x0004, TCTL1   | restart,割り込み不可,|システムクロックの1/16を単位として計時，|タイマ使用停止

		***************************************************************
		** STEP2の処理
		***************************************************************
		*lea.l uart1_interrupt, %a0
		*move.l %a0, 0x110 /* STEP2.1 level 4, (64+4)*4 割り込み処理ルーチンの開始アドレスをレベル4割り込みベクタに設定 */
		move.l #0x00ff3ff9,IMR  |UART1許可

		/*trap #0に登録*/
		move.l #CALL_SYSTEM, 0x080

		move.l #uart1_interrupt, 0x110
		move.l #timer1_interrupt, 0x118 /* タイマ割り込みベクタの登録 */
		

		

        	/* Queue initialize */
        	jsr Init_Q

		jsr LED_CLEAR


		/*step9のMAINへ*/
		bra MAIN		


LED_CLEAR:
	move.b #' ', LED0
	move.b #' ', LED1
	move.b #' ', LED2
	move.b #' ', LED3
	move.b #' ', LED4
	move.b #' ', LED5
	move.b #' ', LED6
	move.b #' ', LED7
	rts
/*trap #0での処理,SYSTEMCALL*/
CALL_SYSTEM:
	*move.w #0x2000, %SR /* こいつのせいで、タイマ割り込みエラー発生 */

	cmpi #1, %d0
	bne CALL_PUT

	*lea.l GETSTRING, %a0
	*move.l (%a0), %d0
	*jmp (%a0)
	
	jsr GETSTRING	
	
	bra CALL_END

CALL_PUT:
	
	cmpi #2, %d0
	bne CALL_RESET

	*lea.l PUTSTRING, %a0
	*move.l (%a0), %d0
	*jmp %a0

	jsr PUTSTRING

	bra CALL_END


CALL_RESET:
	
	cmpi #3, %d0
	bne CALL_SET
	
	*lea.l RESET_TIMER, %a0
	*move.l (%a0), %d0
	*jmp (%a0)
	
	jsr RESET_TIMER
	
	bra CALL_END

CALL_SET:
	
	cmpi #4, %d0
	bne CALL_TYPE_GAME_SETTING

	*lea.l SET_TIMER, %a0
	*move.l (%a0), %d0
	*jmp (%a0)
	
	jsr SET_TIMER
	
	bra CALL_END

CALL_TYPE_GAME_SETTING:
	move.b #'X', LED7
	cmpi #5, %d0
	bne CALL_TYPE_GAME_PRINT
	
	jsr TYPE_GAME_SETTING
	jsr LED_CLEAR
	
	bra CALL_END

CALL_TYPE_GAME_PRINT:
	cmpi #6, %d0
	bne CALL_END

	jsr TYPE_GAME_PRINT_NEW_LINE
	jsr TYPE_GAME_PRINT_TXT
	jsr TYPE_GAME_PRINT_NEW_LINE

	bra CALL_END

CALL_END:
	rte /* ☓ rte -> rts */



*****************************************************************************************
** TIMER SETTING
*****************************************************************************************

************************************************************* 
**RESET_TIMER 
**機能 
**タイマ割り込みを不可にし，タイマも停止する 
************************************************************* 

RESET_TIMER: 
	move.b  #'5', LED3      /*文字’5’をLEDの4桁目に表示*/
	move.w #0x0004, TCTL1 /* 1.TCTL1をタイマ使用停止に設定 */ 
	rts


  
************************************************************* 
**SET_TIMER 
**機能 
**	タイマ割り込みを不可にし，タイマも停止するタイマ割り込み時に呼び出すべきルーチンを設定する 
**	タイマ割り込み周期tを設定し，t*0.1msec秒毎に割り込みが発生するようにする 
**	タイマ使用を許可し，タイマ割り込みを許可する．(=タイマをスタートさせる) 
**入力 
**	d1:タイマ割り込み発生周期 
**	d2:割り込み時に起動するルーチンの先頭アドレス
**戻り値 
**	なし 
*************************************************************
  

SET_TIMER:
	move.b  #'1', LED7      /*文字’1’をLEDの8桁目に表示*/
	move.l %d2, task_p /* 1.割り込みルーチンの先頭アドレスを，task_pに代入 ちょっと変更*/ 
	move.w #0x00ce, TPRER1 /* 2.TPRER1を、0.1msec進むとカウンタが1増えるように設定 */ 
	move.w %d1, TCMP1 /* 3.タイマ割り込み発生周期を，TCMP1に代入 要修正 */ 
	move.w #0x0015, TCTL1 /* 4.TCTL1を割り込み許可に設定 */  
	rts

************************************************************* 
**CALL_RP 
**機能 
**タイマ割り込み時に処理すべきルーチンを呼び出す 
************************************************************* 

CALL_RP: 
	move.b  #'2', LED6      /*文字’2’をLEDの7桁目に表示*/
	movea.l task_p, %a0
	jsr (%a0)
	*jsr task_p /* 1.task_pの指すアドレスへジャンプする ここ自信ないので、なんか修正あったらおねがいします */ 
	rts /* 割り込み処理に戻る */ 

 
************************************************************* 
**p 
**機能 
**タイマ割り込み時の処理ルーチン 
**多分各自で作成 (課題10) 
************************************************************* 
*p: 
	*rts /* CALL_RPに戻る */ 
 



***********************************************************************************************************
**   CALL SETTING
***********************************************************************************************************
/*各システムの呼び出し,tテストではMAINにあるため使用しない?*/
/*GETSTRING呼び出し*/
CALL_GETSTRING:
	move.l #1, %d0		/*GETSTRING*/
	move.l #0,%d1		/*ch=0*/
	move.l #BUF, %d2	/*p=#BUF*/
	move.l #256, %d3	/*size=256*/
	trap #0

/*PUTSTRING呼び出し*/
CALL_PUTSTRING:
	move.l #2, %d0		/*PUTSTRING*/
	move.l #0,%d1		/*ch=0*/
	move.l #BUF, %d2	/*p=#BUF*/
	move.l #256, %d3	/*size=256*/
	trap #0

/*RESET_TIMER呼び出し*/
CALL_RESET_TIMER:
	move.l #3, %d0		/*RESET_TIMER*/
	trap #0

/*SET_TIMER呼び出し*/
CALL_SET_TIMER:
	move.l #4, %d0		/*SET_TIMER*/
	move.w #50000, %d1		/*d1=タイマ割り込み発生周期*/
	move.l #TT, %d2		/*ルーチンの先頭アドレスd2=#TT*/
	trap #0


/*以上step8*/





******************************************************
***システムコール番号
******************************************************
	.equ SYSCALL_NUM_GETSTRING,	1
	.equ SYSCALL_NUM_PUTSTRING,	2
	.equ SYSCALL_NUM_RESET_TIMER,	3
	.equ SYSCALL_NUM_SET_TIMER,	4
	.equ SYSCALL_TYPE_GAME_SET,	5
	.equ SYSCALL_TYPE_GAME_PRINT,	6


******************************************************
***プログラム領域
******************************************************
.section .text
.even
MAIN:						/*走行モードとレベルの設定(ユーザモードへ移行)*/

	move.w #0x0000, %SR				/*USER_MODE_LEBELを0に*/
	lea.l USR_STK_TOP, %SP				/*USER_STACKを設定*/

	
	move.l #TXT_hello, %d1
	move.l #SIZE_hello, %d2

    	jsr TYPE_GAME_SETTING
	jsr TYPE_GAME_INTRO
	jsr TYPE_GAME_PRINT_TXT
	jsr TYPE_GAME_PRINT_NEW_LINE

	bra LOOP
	*move.l #SYSCALL_NUM_RESET_TIMER, %d0		/*システムコールでRESET_TIMERの起動*/
	*trap #0


	*move.l #SYSCALL_NUM_SET_TIMER,%d0		/*システムコールでSET_TIMERの起動*/
	*move.w #50000, %d1
	*move.l #TT, %d2
	*trap #0

	*bra LOOP
	
** !! *********************************
** Typing Game routine
** !! *********************************

**********************
** TYPE_GAME_SETTING
** 引数 %d1.l %d2.l
*********************
TYPE_GAME_SETTING:
	move.l #0, (COUNT_SIZE)
	move.l #0, (COUNT_FAULT)
	move.b #0, (END_FLG)
	move.l %d1, TXT_P
	move.l %d2, (TXT_SIZE)
	
    	rts

TYPE_GAME_INTRO:
	movem.l %d0-%d7,-(%SP)	
   	move.l #SYSCALL_NUM_PUTSTRING, %d0
	move.l #0, %d1				/*ch=0*/
	move.l #INTRO, %d2			/*p=#INTRO*/
	move.l #28, %d3				/*size=8*/
	trap #0
	movem.l (%SP)+, %d0-%d7
	rts

TYPE_GAME_PRINT_TXT:
	movem.l %d0-%d7,-(%SP)	
    	move.l #SYSCALL_NUM_PUTSTRING, %d0
	move.l #0, %d1				/*ch=0*/
	*move.l #TXT_hello, %d2			/*p=#INTRO*/
	move.l (TXT_P), %d2
	*move.l #SIZE_hello, %d3				/*size=8*/
	move.l	(TXT_SIZE), %d3	
	trap #0
	movem.l (%SP)+, %d0-%d7
	rts

TYPE_GAME_PRINT_NEW_LINE:
	movem.l %d0-%d7,-(%SP)	
    	move.l #SYSCALL_NUM_PUTSTRING, %d0
	move.l #0, %d1				/*ch=0*/
	move.l #NEW_LINE, %d2			/*p=#INTRO*/
	move.l #2, %d3				/*size=8*/
	trap #0
	movem.l (%SP)+, %d0-%d7
	rts /* TYPE_GAME_LAST */

ANSI_DEF:

	
ANSI_I:
	







******************************************************
***sys_GETSTRING,SYS_PUTSTRINGのテスト
***ターミナルの入力をエコーバック
******************************************************

LOOP:
	move.l #SYSCALL_NUM_GETSTRING, %d0	/*GETSTRINGの呼び出し*/
	move.l #0, %d1				/*ch=0*/
	move.l #BUF, %d2			/*p=#BUF*/
	move.l #256, %d3			/*size=256*/
	trap #0


	move.l %d0, %d3				/*size=d0*/
	move.l #SYSCALL_NUM_PUTSTRING, %d0	/*PUTSTRINGの呼び出し*/
	move.l #0, %d1				/*ch=0*/
	move.l #BUF, %d2			/*p=#BUF*/
	*move.l #256, %d3				/*size=d0*/
	trap #0
	
	cmp.b #0x01, (END_FLG)
	bne LOOP

TG_SET:	
	
		
	move.l #SYSCALL_TYPE_GAME_SET, %d0	/*PUTSTRINGの呼び出し*/
	move.l #TXT_univ, %d1
	move.l #SIZE_univ, %d2				/*size=d0*/
	trap #0

	move.l #SYSCALL_TYPE_GAME_PRINT, %d0	/*PUTSTRINGの呼び出し*/
	trap #0
	

	bra LOOP

******************************************************
***タイマのテスト
***'******'を表示し改行
***5回実行してRESET_TIMER
******************************************************

TT:
	move.b  #'4', LED4      /*文字’4’をLEDの5桁目に表示*/
	movem.l %d0-%d7/%a0-%a6,-(%SP)		/*レジスタ退避*/
	cmpi.w #5, TTC				/*TTCカウンタで5回実行をカウント*/
	beq TTKILL				/*5回実行したらタイマを停止*/

	move.l #SYSCALL_NUM_PUTSTRING, %d0
	move.l #0, %d1				/*ch=0*/
	move.l #TMSG, %d2			/*p=#TMSG*/
	move.l #8, %d3				/*size=8*/
	trap #0

	addi.w #1, TTC				/*TTCカウンタを1つ増やす*/
	bra TTEND				/*そのまま戻る*/

TTKILL:
	move.l #SYSCALL_NUM_RESET_TIMER, %d0	/*RESET_TIMERの呼び出し*/
	trap #0
TTEND:
	movem.l (%SP)+, %d0-%d7/%a0-%a6		/*レジスタ復帰*/
	rts




*****************************************************
**    割り込みインタフェース
*****************************************************
uart1_interrupt:
	movem.l %d0-%d3, -(%sp)


	move.w URX1, %d3
	move.b %d3, %d2
	cmp.w #0x2000, %d3
	bcc INTERGET


	move.w UTX1, %d0	/*step4:UTX1のコピー*/
	move.l #0, %d1	/*chの選択*/
	cmp.w #0x8000,%d0
	bcc INTERPUT

		
		

	movem.l (%sp)+, %d0-%d3
	rte




************************************************************
** タイマー割り込みインターフェース
************************************************************

timer1_interrupt:
	move.b  #'3', LED5      /*文字’3’をLEDの6桁目に表示*/
	movem.l %d4, -(%sp)

/* 以下修正部分 */
	move.w TSTAT1, %d4
	cmpi.w #0x01, %d4 /* 1.第0ビットが0か比較 */
	bne timer1_end /* 1.第0ビットが0なら、rteで復帰 */
	sub.w #0x01, %d4 /* 2.第0ビットを0クリア */
	move.w %d4, TSTAT1
	jsr CALL_RP
/* 以上修正部分 */

timer1_end:
	*move.w %d3, %SR
	movem.l (%sp)+, %d4
	rte




**************************************************************
** INTERPUT
** 引数
** D1 : チャネルの選択
** 戻り値
**     なし
**************************************************************

INTERPUT:
	movem.l %d0-%d2, -(%sp)

	move.w #0x2700, %SR	/*step4.1:走行レベル7*/
	
	cmp.l #0, %d1		/*step4.2:ch!=0で分岐*/

	bne INTERPUT_END

	move.l #1, %d0
	*move.w #0x0800+'a', UTX1
	jsr OUTQ		/*step4.3:OUTQの実行*/

	cmp.w #0, %d0		/*step4.4:戻り値が0で分岐*/
	beq INTERPUT_MASK
	*move.b %d1, %d2
	addi.w #0x0800, %d1
	*move.w #0x0800+'f', UTX1
	move.w %d1, UTX1	/*step4.5:ヘッダ付与*/

INTERPUT_END:
	*move.w #0x0800+'c', UTX1
	movem.l (%sp)+, %d0-%d2
	movem.l (%sp)+, %d0-%d3
	rte

INTERPUT_MASK:
	*move.w #0x0800+'b', UTX1
	move.w #0xe108, USTCNT1	/*step4.4:送信割り込みのマスク*/
	bra INTERPUT_END


*******************************
**INTERGET
**d1:チャネル
**d2:受信データ
*******************************
INTERGET:
	
	movem.l %a0-%a6/%d0-%d7, -(%SP)

	cmp.l #0, %d1		/*ch!=0で分岐*/
	
	bne INTERGET_END

	move.l #0, %d0		/*キュー番号を設定*/

	move.b %d2,%d1		/*キューに入れるデータをd1に格納*/

	
/* TYPE GAME VERSION ========================================== */    
TYPE_GAME_CHAR_CHECK:
    	
	
	lea.l COUNT_SIZE, %a1
	move.l (%a1), %d5
 	


    	/* 入力が終了していないか確認*/
	*cmp.l   #SIZE_hello, %d5
	cmp.l	(TXT_SIZE), %d5
  	*beq INTERGET_END
	beq END

    	/* 参照すべき文字列を用意する*/

   	move.l (TXT_P), %a1
	
	adda.l %d5, %a1
		
	move.b (%a1), %d6
	 
    	  
	/* 一致しなければ終了する*/
   	cmp.b  %d6, %d1
   	bne FAULT
	
    	/* 文字を出力しカウントをインクリメントする */
	
   	jsr INQ
   	addi.l #1, %d5
   	move.l %d5, (COUNT_SIZE)
	
	
	/* 入力成功表示*/
	bra SUCCESS


****************
** LED
****************
	
LED_SET:
	move.b #'0', %d6
	move.b #'0', %d7

LED_LOOP:
	
	addi.b #0x01, %d6
	cmpi.b #':', %d6
	beq LED_CARRY
	bra LED_LOOP_END
	
LED_CARRY:
	move.b #'0', %d6
	addi.b #0x01, %d7

LED_LOOP_END:
	subq.l #1, %d5
	beq LED_UPDATE
	bra LED_LOOP


LED_UPDATE:

	cmpi.l #0x01, %d4
	beq LED_UPDATE_FAULT_NUMBER
	move.b %d6, LED0
	move.b %d7, LED1
	bra LED_GOOD

LED_UPDATE_FAULT_NUMBER:
	move.b %d6, LED2
	move.b %d7, LED3
	bra LED_BAD


LED_BAD:
	move.b #'B', LED7
	move.b #'A', LED6
	move.b #'D', LED5
	move.b #' ', LED4
	bra INTERGET_END
	
LED_GOOD:
	move.b #'G', LED7
	move.b #'O', LED6
	move.b #'O', LED5
	move.b #'D', LED4
	bra INTERGET_END


LED_END:
	move.b #'E', LED7
	move.b #'N', LED6
	move.b #'D', LED5
	move.b #'!', LED4

	/* FLG UP */
	move.b #0x01, (END_FLG)
	bra INTERGET_END


****************
** typing data
****************
FAULT:
	lea.l COUNT_FAULT, %a1
	move.l (%a1), %d5

	addi.l #1, %d5
   	move.l %d5, (COUNT_FAULT)


	/* 失敗回数を記録する*/
	move.l #0x01 , %d4
	bra LED_SET

SUCCESS:	
	move.l #0x00 , %d4
	bra LED_SET

END:
	bra LED_END	
/* TYPE GAME VERSION ========================================== */   

INTERGET_END:
	movem.l (%SP)+, %a0-%a6/%d0-%d7
	movem.l (%sp)+, %d0-%d3
	
	rte



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
	movem.l %a0-%a6/%d1-%d7, -(%SP)

	cmp.l #0, %d1		/*ch!=0で分岐*/
	
	bne PUTSTRING_END
	
	move.l #0,%d4 		/*%d4=sz:送信したデータ数を格納*/

	move.l %d2,%a1 		/*%d5:データの読み込み先アドレス*/

	cmp.l #0,%d3		/*size=0で分岐*/

	beq PUTSTRING_END

LOOP_STEP5:
	cmp.l %d4,%d3		/*sz=sizeで分岐*/

	beq PUTSTRING_MASK

	move.l #1,%d0 		/*キュー番号の設定*/

	move.b (%a1)+,%d1	/*データをINQの入力d1に格納*/

	jsr INQ

	cmp.l #0,%d0		/*成功or失敗判定*/

	beq PUTSTRING_MASK


	addq #1,%d4		/*sz++*/

	bra LOOP_STEP5

PUTSTRING_MASK:
	move.w #0xe10c, USTCNT1	/*送信割り込み許可*/

	bra PUTSTRING_END

PUTSTRING_END:
	move.l %d4,%d0		/*戻り値d0に実際に送信したデータ数を格納*/
	
	movem.l (%SP)+, %a0-%a6/%d1-%d7

	rts 			/*?*/


*************************************************************
**GETSTRING
**入力
**d1:チャネル
**d2:データ書き込み先の先頭アドレス
**d3:取り出すデータの数
**戻り値
**d0:実際に取り出したデータの数
*************************************************************
GETSTRING:
	*move.w #0x0800+'c', UTX1
	movem.l %a0-%a6/%d1-%d7, -(%SP)

	cmp.l #0, %d1		/*ch!=0で分岐*/
	
	bne GETSTRING_END

	move.l #0,%d4 		/*%d4=sz:取り出したデータ数を格納*/

	move.l %d2,%a1 		/*%a1:データの書き込みアドレス*/

LOOP_STEP6:
	cmp.l %d4,%d3		/*sz=sizeで分岐*/

	beq GETSTRING_END
	
	move.l #0,%d0 		/*キュー番号の設定*/
	
	jsr OUTQ
	
	cmp.l #0,%d0		/*成功or失敗判定*/

	beq GETSTRING_END

	move.b %d1,(%a1)+	/*取り出したデータをコピー*/

	addq #1,%d4		/*sz++*/

	bra LOOP_STEP6

GETSTRING_END:
	move.l %d4,%d0		/*戻り値d0に実際に取り出したデータ数を格納*/

	movem.l (%SP)+, %a0-%a6/%d1-%d7

	rts




************************************************************************************************************
***      QUEUE SETTING
************************************************************************************************************

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
    lea.l QUEUE_SIZE-1(%a0), %a1 /* a1 == BOTTOM = キューnの終端アドレス */
    move.l %a1,BOTTOM(%a0)/*キューnのBOTTOMにa1を格納*/
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


***** 



******************************************************
*** 初期化のあるデータ領域
******************************************************

.section .data
TMSG:
	.ascii	"******\r\n"			/*r:行頭へ,n:改行*/
.even
TTC:
	.dc.w 0
	.even

********************************
** preparation to typing game
********************************
NEW_LINE:
    /* size : 2 */
    .ascii "\r\n"
INTRO:
    /* size : 28*/
    .ascii "Please type this sentence!\r\n"
TXT_hello:
    /* size : 11*/
    .ascii "hello world"

.equ SIZE_hello, 11

TXT_univ:
    .ascii "Kyushu university, Ito campus"

.equ SIZE_univ, 29

***********
** ANSI
************
*CODE_DEF:
*	.ansi "\e[0m"


******************************************************
*** 初期化のないデータ領域
******************************************************
.section .bss

/* type game ------------------------------ */
COUNT_FAULT:
	.ds.l 0x01
COUNT_SIZE:
    .ds.l 0x01
TXT_P:
	.ds.l 0x01
TXT_SIZE:
	.ds.l 0x01
END_FLG:
	.ds.b 0x01

/* ------------------------------------- */
task_p:
	.ds.l	0x01
	.even

BUF:
	.ds.b 256				/*BUF[256]*/
	.even



USR_STK:
	.ds.b 0x4000				/*ユーザスタック領域*/
	.even

USR_STK_TOP:				/*ユーザスタック領域の最後尾*/



