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

