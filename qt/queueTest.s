
.section .data
    *************************
    ** test congfig
    *************************
    /* *_count の値を変更して繰り返し変え数を決定する */
    .equ IN_COUNT, 257
    .equ OUT_COUNT, 257
    .equ queue_number, 0


    **************************
    ** queue congfig
    **************************

.section .text

** 0x1000からデータを適当に入力する
** 0x1300にとりだされたデータが格納される
** 0x1600に戻り値1 or 0が格納される

start:
    jsr Init_Q

    move.l #0x1000, %A1
    move.l #0x1300, %A2
    move.l #0x1600, %A3
    move.l #0x1900, %A4
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
    move.l %D0, (%A3)+

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
    move.l %D0, (%A4)+

    subq.l #1, %d3
    bne out_loop
    bra finish


/* キュー領域の前後での書き込みが発生していないことを確認すること*/
/* キュー領域の前後での書き込みが発生していないことを確認すること*/
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
.section .text
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
    move.l  %a1, BOTTOM(%a0) /* a1 = キューnのBOTTOMのアドレス */

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

