


*****
** out queue => utx1
*****

interput:
	move.l %D0-%D7/%A0-%A6, -(%SP)
	/* dont inerput!   level 7 */
	move.w	#2700, %SR
	
	/* (2) */
	cmpi.l #1, %d1
	bne	interput_finish

	/* (3) */
	/* OUTQ(1, data) */
		
	lea.l ADDRESS_DATA, %a1
	jsr OUTQ
	
	/*  (4)*/
	/* return 0 from  OUTQ => ustcnt1 */
     	
	/* set return address of the reg. */
	cmpi.l #0, %d0
        beq	ustcnt1
	


	/* (5) */
	/* data => utx1 (! need to input headder)*/
	** mask?
	


interput_finish:
	move.l	(%SP)+, %D0-%D7 / %A0-%A6
	/* rte*/
	rts
	
	




/* ====================================================== */


********
**   UART1の割り込みが、送信割り込みであるとき送信レジスタUTX1の１５ビット目をチェックする
**   送信割り込みであったときD1=0としてinterput
*********
	
 
