/* *_count の値を変更して繰り返し変え数を決定する */
.section .data
	.equ	IN_COUNT, 128
	.equ	OUT_COUNT, 129
	.equ	queue_number, 0

.section .text

** 0x1000からデータを適当に入力する
** 0x1300にとりだされたデータが格納される
** 0x1600に戻り値1 or 0が格納される

start:
	
	move.l	#0x1000, %A1
	move.l	#0x1300, %A2
	move.l	#0x1600, %A3
	
finish:
	stop	#2700


/* =============================== */
in_set:
	move.l	IN_COUNT, %d3

in_loop:
	move.l	queue_number, %d0
	
	/* 書き込むべきデータを与える */
	move.b	(%A0)+, %D1

	**jsr	INQ
	/* 戻り値の格納 */
	move.l	%D0, (%A1)+

	subq.l	#1, %d3
	bne	in_loop
	bra	out_set

/* ================================ */
	

out_set:
	move.l	OUT_COUNT, %d3

out_loop:
	move.l	queue_number, %d0
	** jsr OUTQ

	/* データと戻り値をメモリに格納しておく*/
	move.b	%D1, (%A2)+
	move.l	%D0, (%A3)+

	subq.l	#1, %d3
	bne out_loop
	bra finish	


/* キュー領域の前後での書き込みが発生していないことを確認する*/


/* 以下に　INQ と OUTQ を貼り付ける*/




