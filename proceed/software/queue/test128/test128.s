.section .text

** 0x1000からデータを適当に入力する
** 0x1300にとりだされたデータが格納される
** 0x1600に戻り値1/0が格納される

start:
	move.l	#0x1000, %A1
	move.l	#0x1300, %A2
	move.l	#0x1600, %A3
	
finish:
	stop	#2700


/* =============================== */
test_in_set:
	move.l	#128, %d3

loop_in_test:
	**jsr	INQ
	move.l	%D0, (%A1)+
	subq.l	#1, %d3
	bne	loop_in_test
	bra	loop_out_set

/* ================================ */
	

loop_out_set:
	move.l	#129, %d3

loop_out_test:
	** jsr OUTQ
	move.l %D0	


/* 以下に　INQ と OUTQ を貼り付ける*/




