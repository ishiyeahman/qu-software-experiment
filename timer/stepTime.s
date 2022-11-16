/*以下step8*/

/*trap #0に登録*/
lea.l CALL_SYSTEM, %a0
move.l %a0, 0x080

bra MAIN		/*step9のMAINへ*/

/*trap #0での処理,SYSTEMCALL*/
CALL_SYSTEM:
	move.w #0x2000, %SR

	cmpi #1, %d0
	bne CALL_PUT
	lea.l GETSTRING, %a0
	move.l (%a0), %d0
	jmp (%a0)
	bra CALL_END

CALL_PUT:
	cmpi #2, %d0
	bne CALL_RESET
	lea.l PUTSTRING, %a0
	move.l (%a0), %d0
	jmp (%a0)
	bra CALL_END

CALL_RESET:
	cmpi #3, %d0
	bne CALL_SET
	lea.l RESET_TIMER, %a0
	move.l (%a0), %d0
	jmp (%a0)
	bra CALL_END

CALL_SET:
	cmpi #4, %d0
	bne CALL_END
	lea.l SET_TIMER, %a0
	move.l (%a0), %d0
	jmp (%a0)
	bra CALL_END

CALL_END:
	rte

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
	move.w #0,%d1		/*d1=タイマ割り込み発生周期*/
	move.l #BUF, %d2	/*p=#BUF*/
	trap #0


/*以上step8*/





******************************************************
***システムコール番号
******************************************************
	.equ SYSCALL_NUM_GETSTRING,	1
	.equ SYSCALL_NUM_PUTSTRING,	2
	.equ SYSCALL_NUM_RESET_TIMER,	3
	.equ SYSCALL_NUM_SET_TIMER,	4


******************************************************
***プログラム領域
******************************************************
.section .text
.even
MAIN:						/*走行モードとレベルの設定(ユーザモードへ移行)*/

	move.w #0x0000, %SR				/*USER_MODE_LEBELを0に*/
	lea.l USR_STK_TOP, %SP				/*USER_STACKを設定*/


	move.l #SYSCALL_NUM_RESET_TIMER, %d0		/*システムコールでRESET_TIMERの起動*/
	trap #0


	move.l #SYSCALL_NUM_SET_TIMER,%d0		/*システムコールでSET_TIMERの起動*/
	move.w #50000, %d1
	move.l #TT, %d2
	trap #0

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

	bra LOOP

******************************************************
***タイマのテスト
***'******'を表示し改行
***5回実行してRESET_TIMER
******************************************************

TT:
	movem.l %d0-%d7/%a0-%a6,-(%SP)		/*レジスタ退避*/
	cmpi.w #5, TTC				/*TTCカウンタで5回実行をカウント*/
	beq TTKILL				/*5回実行したらタイマを停止*/

	move.l #SYSCALL_NUM_PUTSTRING, %d0
move.l #0, %d1					/*ch=0*/
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






******************************************************
***初期化のあるデータ領域
******************************************************

.section .data
TMSG:
.ascii	"******\r\n"			/*r:行頭へ,n:改行*/
.even
TTC:
.dc.w 0
.even

******************************************************
***初期化のないデータ領域
******************************************************
.section .bss
BUF:
.ds.b 256				/*BUF[256]*/
.even

USR_STK:
.ds.b 0x4000				/*ユーザスタック領域*/
.even

USR_STK_TOP:				/*ユーザスタック領域の最後尾*/




