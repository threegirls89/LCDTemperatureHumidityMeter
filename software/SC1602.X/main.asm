#include "p16F1827.inc"

; CONFIG1
 __CONFIG _CONFIG1,  0x3FC4
; __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_ON & _FCMEN_ON
; CONFIG2
 __CONFIG _CONFIG2, 0x3FFF
;__CONFIG _CONFIG2, _WRT_OFF & _PLLEN_ON & _STVREN_ON & _BORV_LO & _LVP_ON

; SC1602 to PIC16F1827 pin connection
; RS -> RA2 -> RA0
; R/W -> RA1 -> RA6
; E -> RA0 -> RA7
; DB0-7 -> RB0-7 -> RB5,4,7,6,3,2,1,0: RB7-0 -> DB2,3,0,1,4,5,6,7
; DHT11 RA4

; file registers
LCDRSRW EQU     20H
LCDDATA EQU     21H
CNTW37U EQU     22H
CNTW1M5 EQU     23H

CNTRDBIT    EQU 24H
DATDHTRD    EQU 25H
CNTDHTTH    EQU 26H
TMPRTURE    EQU 27H
HUMIDITY    EQU 28H
_TMPRTURE   EQU 29H
_HUMIDITY   EQU 2AH
DIG100      EQU 2BH
DIG10       EQU 2CH
DIG1        EQU 2DH
PARITY      EQU 2EH
HEXNUM      EQU 2FH

        ORG      00H          ; processor reset vector
        GOTO    START                   ; go to beginning of program

ISR
        ORG      04H          ; interrupt vector location
        RETFIE

DIG2LCD ADDWF   PCL,1
        RETLW   B'00001100'
        RETLW   B'00101100'
        RETLW   B'00011100'
        RETLW   B'00111100'
        RETLW   B'10001100'
        RETLW   B'10101100'
        RETLW   B'10011100'
        RETLW   B'10111100'
        RETLW   B'01001100'
        RETLW   B'01101100'


START
        BANKSEL OSCCON
        MOVLW   B'01111000'
        MOVWF   OSCCON
        BANKSEL ANSELA
        CLRF    ANSELA
        CLRF    ANSELB
        BANKSEL LATA
        CLRF    LATA
        CLRF    LATB
        BANKSEL TRISA
        MOVLW   B'00000000'
        MOVWF   TRISA
        MOVLW   B'00000000'
        MOVWF   TRISB

        CLRF    BSR
        CLRF    LCDRSRW
        CLRF    LCDDATA
        BSF     PORTA,4
        BCF     PORTA,0

        BCF     LCDRSRW,0
        BCF     LCDRSRW,6
        MOVLW   B'01001100'
        MOVWF   LCDDATA
        CALL    LCDWRIT
        CALL    WAIT37US
        CALL    LCDWRIT
        CALL    WAIT37US

        MOVLW   B'00100000'
        MOVWF   LCDDATA
        CALL    LCDWRIT
        CALL    WAIT1M5S

        MOVLW   B'11000000'
        MOVWF   LCDDATA
        CALL    LCDWRIT
        CALL    WAIT37US

        MOVLW   B'10010000'
        MOVWF   LCDDATA
        CALL    LCDWRIT
        CALL    WAIT37US

        MOVLW   B'00000001'
        MOVWF   LCDDATA
        CALL    LCDWRIT
        CALL    WAIT37US
;initialize finished

        CALL    DHTREAD
        BSF     LCDRSRW,0


        MOVF    TMPRTURE,0
        MOVWF   HEXNUM
        MOVLW    B'00000100'
        BTFSS   TMPRTURE,7
        GOTO    DSPLTMPR
        COMF    TMPRTURE,0
        ADDLW   B'00000001'
        MOVWF   HEXNUM
        MOVLW    B'11100100'
DSPLTMPR
        MOVWF   LCDDATA
        CALL    LCDWRIT
        CALL    WAIT37US
        CALL    DSPLBCD

        MOVLW    B'11111011'
        MOVWF   LCDDATA
        CALL    LCDWRIT
        CALL    WAIT37US
        MOVLW    B'00110010'
        MOVWF   LCDDATA
        CALL    LCDWRIT
        CALL    WAIT37US
        MOVLW    B'00000101'
        MOVWF   LCDDATA
        CALL    LCDWRIT
        CALL    WAIT37US

        MOVF    HUMIDITY,0
        MOVWF   HEXNUM
        CALL    DSPLBCD

        MOVLW    B'10100100'
        MOVWF   LCDDATA
        CALL    LCDWRIT
        CALL    WAIT37US


        CALL    WAIT1S
        RESET
LOOP
        GOTO    LOOP

; variables LCDRSRW(RS, R/W bits),  LCDDATA(DATA byte) should be set before call
LCDWRIT 
        MOVLW   B'00111110'
        ANDWF   PORTA,1
        MOVF    LCDRSRW,0
        IORWF   PORTA,1
        MOVF    LCDDATA,0
        MOVWF   PORTB
        BSF     PORTA,7
        NOP             ; to ensure puls witdth of E and DATA
        NOP             ; to ensure puls witdth of E and DATA
        BCF     PORTA,7
        RETURN
; DISPLAY DECIMAL CALL AFTER HEXNUM SET
DSPLBCD
        CALL    HEX2BCD
        MOVF    DIG100,0
        CALL    DIG2LCD
        MOVWF   LCDDATA
        CALL    LCDWRIT
        CALL    WAIT37US
        MOVF    DIG10,0
        CALL    DIG2LCD
        MOVWF   LCDDATA
        CALL    LCDWRIT
        CALL    WAIT37US
        MOVF    DIG1,0
        CALL    DIG2LCD
        MOVWF   LCDDATA
        CALL    LCDWRIT
        CALL    WAIT37US
        RETURN

; HEXADECIMAL TO BCD
HEX2BCD
        CLRF    DIG100
        CLRF    DIG10
        CLRF    DIG1
DIV100
        MOVLW   D'100'
        SUBWF   HEXNUM,0
        BTFSS   STATUS,C
        GOTO    DIV10
        MOVWF   HEXNUM
        INCF    DIG100,1
        GOTO    DIV100
DIV10
        MOVLW   D'10'
        SUBWF   HEXNUM,0
        BTFSS   STATUS,C
        GOTO    DIV1
        MOVWF   HEXNUM
        INCF    DIG10,1
        GOTO    DIV10
DIV1
        MOVLW   D'1'
        SUBWF   HEXNUM,0
        BTFSS   STATUS,C
        RETURN
        MOVWF   HEXNUM
        INCF    DIG1,1
        GOTO    DIV1

; READ DHT11
DHTREAD
        BANKSEL TRISA
        BCF     TRISA,4
        BANKSEL PORTA
        BCF     PORTA,4
        CALL    WAIT20MS
;        BSF     PORTA,4
        BANKSEL TRISA
        BSF     TRISA,4
        BANKSEL PORTA
        CLRF   PARITY
        CALL    WAIT37US

CHKDHTRESF1
        BTFSC   PORTA,4
        GOTO    CHKDHTRESF1
CHKDHTRESR
        BTFSS   PORTA,4
        GOTO    CHKDHTRESR
CHKDHTRESF2
        BTFSC   PORTA,4
        GOTO    CHKDHTRESF2

;ok

        CALL    DHTREAD1B
        MOVF    DATDHTRD,0
        MOVWF   _HUMIDITY
        ADDWF   PARITY,1

        CALL    DHTREAD1B
        MOVF    DATDHTRD,0
        ADDWF   PARITY,1

;ok
        CALL    DHTREAD1B
        MOVF    DATDHTRD,0
        MOVWF   _TMPRTURE
        ADDWF   PARITY,1

        CALL    DHTREAD1B
        MOVF    DATDHTRD,0
        ADDWF   PARITY,1


        CALL    DHTREAD1B
        MOVF    DATDHTRD,0
        XORWF   PARITY,0
        BTFSS   STATUS,Z
        RETURN

        MOVF    _TMPRTURE,0
        MOVWF   TMPRTURE
        MOVF    _HUMIDITY,0
        MOVWF   HUMIDITY
        RETURN

; READ 1 BYTE FROM DHT11
DHTREAD1B
        MOVLW   D'8'
        MOVWF   CNTRDBIT
        CLRF    DATDHTRD
LPDHTRD1B
        CLRF    CNTDHTTH
; CHECK PORTA[4] RISES
CHKDHTRISE
        BTFSS   PORTA,4
        GOTO    CHKDHTRISE
CHKDHTFALL; 4 CYCLE = 4/4 [us] PER LOOP
        INCF    CNTDHTTH,1
        BTFSC   PORTA,4
        GOTO    CHKDHTFALL

        MOVLW   D'48'
        SUBWF   CNTDHTTH,0 ; RISE C FLAG WHEN PULSE IS LONG (I.E. BIT = 1)
        RLF     DATDHTRD,1
        DECFSZ  CNTRDBIT,1
        GOTO    LPDHTRD1B
        RETURN



WAIT37US
        MOVLW   D'40'    ;221 for 56us 146 for 37us
        MOVWF   CNTW37U
LPW37US
        NOP
        DECFSZ  CNTW37U,1
        GOTO    LPW37US
        RETURN

WAIT1M5S
        MOVLW   D'41'
        MOVWF   CNTW1M5
LPW1M5S
        CALL    WAIT37US
        DECFSZ  CNTW1M5,1
        GOTO    LPW1M5S
        RETURN
WAIT20MS
        MOVLW   D'13'
        MOVWF   31H
LPW20MS
        CALL    WAIT1M5S
        DECFSZ  31H,1
        GOTO    LPW20MS
        RETURN


WAIT1S  MOVLW   D'50'
        MOVWF   30H
LPW1S   CALL    WAIT20MS
        DECFSZ  30H,1
        GOTO    LPW1S
        RETURN


        END