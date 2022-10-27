/*=========レジスタ定義=========*/

** レジスタ群の先頭
.equ    REGBASE, 0xFFF000
.equ    IOBASW, 0x00d00000

** 割り込み関係のレジスタ
.equ    IVR, REGBASE+0x300  |割り込みベクタレジスタ
.equ    IMR, REGBASE+0x304  |割り込みマスタレジスタ
.equ    ISR, REGBASE+0x30c  |割り込みステータスレジスタ
.equ    IPR, REGBASE+0x310  |割り込みペンディングレジスタ

** タイマ関係のレジスタ
.equ    TCTL1,  REGBASE+0x600
.equ    TPRER1, REGBASE+0x602
.equ    TCMP1,  REGBASE+0x604
.equ    TCN1,   REGBASE+0x608
.equ    TSTAT1, REGBASE+0x60a

** UART1 (送受信関係)のレジスタ
.equ    USTCINT1, REGBASE+0x900
.equ    UBAUD1, REGBASE+0x902
.equ    URX1,   REGBASE+0x904
.equ    UTX1,   REGBASE+0x906

** LED
.equ    LED7,   IOBASE+0x000002f
.equ    LED6,   IOBASE+0x000002d
.equ    LED5,   IOBASE+0x000002b
.equ    LED4,   IOBASE+0x0000029
.equ    LED3,   IOBASE+0x000003f
.equ    LED2,   IOBASE+0x000003d
.equ    LED1,   IOBASE+0x000003b
.equ    LED0,   IOBASE+0x0000039


/* ===== スタック領域の確保 ===== */
.section .bss
.even
SYS_STK:
    .ds.b   0x4000  |システムスタック領域
    .even

SYS_STK_TOP:

/* ======== 初期化 ========= */
.section .text
.even
boot:
    /* スーパーバイザ : 各種設定を行っている最中の割込み禁止 */
    move.w  #0x2700, %SR
    lea.l   SYS_STK_TOP, %SR    /* SR に セット */

    /* ======== 割り込みコントローラの初期化 ======== */
    
    move.b  #0x40,  IVR      /* ユーザ割り込みベクタ番号を0x40+levelに設定 */
    move.l  #0x00ffffff, IMR /* 全割り込みマスク */
