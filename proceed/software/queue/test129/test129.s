.section .text

** 0x1000からデータを適当に入力する
** 0x1300にとりだされたデータが格納される
** 0x1600に戻り値1/0が格納される

START:
	move.l	#0x1000, %A1
	move.l	#0x1300, %A2
	move.l	#0x1600, %A3
	


test_128:
	move.l	#128, %d3

loop_test_128:
	**jsr	INQ
	move.l	%D0, (%A1)+
	subq.l	#1, %d3
	bn
	


/* ================================ */
	




/* 以下に　INQ と OUTQ を貼り付ける*/
