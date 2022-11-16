/* *_count の値を変更して繰り返し変え数を決定する */
.section .data
.equ IN_COUNT, 128
.equ OUT_COUNT, 129
.equ queue_number, 0
.equ OFFSET_1, 0x100
.equ END_0, 0xff
.equ END_1, 0x1ff
top: .ds.b 0x200
bottom: .ds.w 2
in: .ds.l 1
in_0: .ds.l 1
in_1: .ds.l 1

out: .ds.l 1
out_0: .ds.l 1
out_1: .ds.l 1

s: .ds.l 1
s0: .ds.l 1
s1: .ds.l 1

**PUT_FLG: .ds.b 1
**PUT_FLG_0: .ds.b 1
**PUT_FLG_1: .ds.b 1

**GET_FLG: .ds.b 1
**GET_FLG_0: .ds.b 1
**GET_FLG_1: .ds.b 1

START_LABEL: .ds.l 1

.section .text

** 0x1000からデータを適当に入力する
** 0x1300にとりだされたデータが格納される
** 0x1600に戻り値1 or 0が格納される

start:
	jsr Init_Q

	move.l #0x1000, %A1
	move.l #0x1300, %A2
	move.l #0x1600, %A3
	bra in_set

finish:
	stop #2700


/* =============================== */
in_set:
	move.w #IN_COUNT, %d3

in_loop:
	move.w #queue_number, %d0

	/* 書き込むべきデータを与える */
	move.b (%A1)+, %D1

	jsr INQ
	/* 戻り値の格納 */
	move.b %D0, (%A3)+

	subq.l #1, %d3
	bne in_loop
	bra out_set

/* ================================ */


out_set:
	move.w #OUT_COUNT, %d3

out_loop:
	move.w #queue_number, %d0
	jsr OUTQ

/* データと戻り値をメモリに格納しておく*/
	move.b %D1, (%A2)+
	move.b %D0, (%A3)+

	subq.l #1, %d3
	bne out_loop
	bra finish


/* キュー領域の前後での書き込みが発生していないことを確認する*/


/* 以下に　INQ と OUTQ を貼り付ける*/
Init_Q:
	movem.l %d0-%d6/%a1-%a6, -(%sp)

	lea.l top, %a2
	move.l %a2, in_0
	move.l %a2, out_0
	lea.l OFFSET_1(%a2), %a3
	move.l %a3, in_1
	move.l %a3, out_1
	lea.l s, %a4
	lea.l s0, %a5
	lea.l s1, %a6
	move.l #0,(%a4)
	move.l #0,(%a5)
	move.l #0,(%a6)
**move.b #0xff, PUT_FLG_0
**move.b #0xff, PUT_FLG_1
**move.b #0x00, GET_FLG_0
**move.b #0x00, GET_FLG_1

	movem.l (%sp)+,%d0-%d6/%a1-%a6

rts

*****************************************************************
INQ:
	jsr SELECT_QUEUE
	jsr PUT_BUF

rts
**************************************************************
SELECT_QUEUE:
	cmp.b #0, %d0
	beq SET_0
	cmp.b #1, %d0
	beq SET_1
	
**move.b #0x00, PUT_FLG
**move.b #0x00, GET_FLG
	rts

SET_0:


	movem.l %d0-%d6/%a1-%a6, -(%sp)

	move.l in_0, in
	move.l out_0, out
**move.b PUT_FLG_0, PUT_FLG
**move.b GET_FLG_0, GET_FLG
	move.l %a2, START_LABEL
	lea.l END_0(%a2), %a3
	move.l %a3, bottom
	move.l s0,s
	
	movem.l (%sp)+,%d0-%d6/%a1-%a6


	rts	

SET_1:



	movem.l %d0-%d6/%a1-%a6, -(%sp)

	move.l in_1, in
	move.l out_1, out
	**move.b PUT_FLG_1, PUT_FLG
	**move.b GET_FLG_1, GET_FLG
	lea.l OFFSET_1(%a2), %a3
	move.l %a3, START_LABEL
	lea.l END_1(%a2), %a3
	move.l %a3, bottom
	move.l s0,s

	movem.l (%sp)+,%d0-%d6/%a1-%a6

	rts

*************************************************************************


PUT_BUF:
movem.l %a1-%a6, -(%sp)

move.b s,%d2
cmp.w #0x100,%d2
beq PUT_FAIL 
move.b #1,%d2 /*成功*/
movea.l in, %a1
move.b %d1, (%a1)+        
move.l bottom, %a3
cmpa.l %a3, %a1
bls PUT_BUF_STEP1
move.l START_LABEL, %a2
movea.l %a2, %a1

PUT_BUF_STEP1:
move.l %a1, in
cmpa.l out, %a1
bne PUT_BUF_STEP2
**move.b #0x00, PUT_FLG

PUT_BUF_STEP2:
**move.b #0xff, GET_FLG
jsr UPDATE
bra PUT_BUF_Finish

PUT_FAIL:
move.b #0,%d2 /*失敗*/

PUT_BUF_Finish:


movem.l (%sp)+, %a1-%a6


rts

****************************************************************

UPDATE:
cmp #0, %d0
beq QUEUE_0
cmp #1, %d0
beq QUEUE_1
rts

QUEUE_0:
move.l in, in_0
**move.b PUT_FLG, PUT_FLG_0
move.l out, out_0
**move.b GET_FLG, GET_FLG_0
move.l s,s0
move.b %d2,%d0 /*成功or失敗の返り値*/

rts
QUEUE_1:
move.l in, in_1
**move.b PUT_FLG, PUT_FLG_1
move.l out, out_1
**move.b GET_FLG, GET_FLG_1
move.l s,s1
move.b %d2,%d0 /*成功or失敗の返り値*/
rts

********************************************
OUTQ:
jsr SELECT_QUEUE
jsr GET_BUF
rts
*********************************************
GET_BUF:
	movem.l %a1-%a6, -(%sp)

	move.b s,%d2
	cmp.b #0x00,%d2
	beq GET_FAIL

	move.b #1,%d2 /*成功*/
	movea.l out, %a1
	move.b (%a1)+, %d1     
move.l bottom, %a3
cmpa.l %a3, %a1
bls GET_BUF_STEP1
move.l START_LABEL, %a2
movea.l %a2, %a1

GET_BUF_STEP1:
	move.l %a1, out
	cmpa.l in, %a1
	bne GET_BUF_STEP2
	**move.b #0x00, GET_FLG

GET_BUF_STEP2:
	**move.b #0xff, PUT_FLG
	jsr UPDATE
	bra GET_BUF_Finish

GET_FAIL:
	move.b #0,%d2 /*失敗*/
	GET_BUF_Finish:
	movem.l (%sp)+, %a1-%a6
rts



