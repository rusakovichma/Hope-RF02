.include "m8def.inc"

.def	ChkSum = r22
.def	OSRG = r17
.equ	PORT_SEL	= PORTB
.equ	PIN_SEL		= PINB
.equ	DDR_SEL		= DDRB

.equ	PORT_SDI	= PORTB
.equ	PIN_SDI		= PINB
.equ	DDR_SDI		= DDRB

.equ	PORT_SCK	= PORTB
.equ	PIN_SCK		= PINB
.equ	DDR_SCK		= DDRB

.equ	PORT_nIRQ	= PORTB
.equ	PIN_nIRQ	= PINB
.equ	DDR_nIRQ	= DDRB

.equ	PORT_FSK	= PORTB
.equ	PIN_FSK		= PINB
.equ	DDR_FSK		= DDRB

.equ	RFXX_SCK	= 1
.equ	RFXX_nIRQ	= 4
.equ	RFXX_SDI	= 0
.equ	RFXX_SEL	= 2
.equ	RFXX_FSK	= 3

.DSEG
RfBuffer:		.db	0,0,0,0

.CSEG 
; Interrupts;===================================================================
			.ORG 	0x0000
				 rjmp RESET

			.ORG	INT0addr		; External Interrupt Request 0
			rjmp  INT0_int
			.ORG	INT1addr		; External Interrupt Request 1
			RETI
			.ORG	OC2addr			; Timer/Counter2 Compare Match
			RETI
			.ORG	OVF2addr		; Timer/Counter2 Overflow
			RETI
			.ORG	ICP1addr		; Timer/Counter1 Capture Event
			RETI
			.ORG	OC1Aaddr		; Timer/Counter1 Compare Match A
			RETI
			.ORG	OC1Baddr		; Timer/Counter1 Compare Match B
			RETI
			.ORG	OVF1addr		; Timer/Counter1 Overflow
			RETI
			.ORG	OVF0addr		; Timer/Counter0 Overflow
			RETI
			.ORG	SPIaddr			; Serial Transfer Complete
			RETI
			.ORG	URXCaddr		; USART, Rx Complete
			RETI
			.ORG	UDREaddr		; USART Data Register Empty
			RETI
			.ORG	UTXCaddr		; USART, Tx Complete
			RETI
			.ORG	ADCCaddr		; ADC Conversion Complete
			RETI 
			.ORG	ERDYaddr		; EEPROM Ready
			RETI
			.ORG	ACIaddr			; Analog Comparator
			RETI
			.ORG	TWIaddr			; 2-wire Serial Interface
			RETI
			.ORG	SPMRaddr		; Store Program Memory Ready
			RETI
; End Interrupts ==========================================

.org INT_VECTORS_SIZE
;=============================================================================
INT0_int:

rcall Rf02_Transmitting

	ldi		r16,(1<<4)
	in		r17,portD
	eor		r17,r16
	out		portD,r17

reti

RESET:
		LDI R16,Low(RAMEND)		
	  	OUT SPL,R16			
 
	  	LDI R16,High(RAMEND)
	  	OUT SPH,R16
RAM_Flush:	
		LDI	ZL,Low(SRAM_START)	
		LDI	ZH,High(SRAM_START)
		CLR	R16			
Flush:		
		ST 	Z+,R16			
		CPI	ZH,High(RAMEND+1)	
		BRNE	Flush			
 
		CPI	ZL,Low(RAMEND+1)	
		BRNE	Flush
 
		CLR	ZL			
		CLR	ZH

		LDI	ZL, 30		
		CLR	ZH		
		DEC	ZL		
		ST	Z, ZH		
		BRNE	PC-2
;------------------------------------------------------
	ldi	r16,$ff		
	out	DDRB,r16
	out	DDRD,r16	

	ldi	r16,$0
	out	portD,r16
	out	portB,r16
;------------------------------------------------------
	rcall IniWDT

	rcall IniOfRf02

	ldi		r16,(1<<3)
	in		r17,portD
	eor		r17,r16
	out		portD,r17

	
	ldi r16, (1<<ISC01)|(1<<ISC11)
	out MCUCR, r16
	ldi r16, (1<<INT0)
	out GIMSK, r16

	SEI

Loop:
	wdr
rjmp Loop

;-------------------------------------------------------------------
IniOfRf02:
	sbi		PORT_SEL,RFXX_SEL
	sbi		PORT_SDI,RFXX_SDI
	cbi		PORT_SCK,RFXX_SCK
	cbi		PORT_FSK,RFXX_FSK

	sbi		DDR_SEL,RFXX_SEL
	sbi		DDR_SDI,RFXX_SDI
	cbi		DDR_nIRQ,RFXX_nIRQ
	sbi		DDR_SCK,RFXX_SCK
	sbi		DDR_FSK,RFXX_FSK
;
	ldi		r19,$00
	ldi		r20,$cc
	rcall	RFXX_WRT_CMD	;Status register read

	ldi		r19,$81
	ldi		r20,$8B
	rcall	RFXX_WRT_CMD	;band=433MHz, frequency deviation = 60kHz

	ldi		r19,$40
	ldi		r20,$a6
	rcall	RFXX_WRT_CMD	;f=434MHz

	ldi		r19,$40
	ldi		r20,$d0
	rcall	RFXX_WRT_CMD	;???RATE/2

	ldi		r19,$23
	ldi		r20,$c8
	rcall	RFXX_WRT_CMD	

	ldi		r19,$20
	ldi		r20,$c2
	rcall	RFXX_WRT_CMD	;enable TX bit sinchronization, no Low Battary Detector

	ldi		r19,$01
	ldi		r20,$c0
	rcall	RFXX_WRT_CMD	;disable CLK pin
ret
;-------------------------------------------------------------------
RFXX_WRT_CMD:
	push	r16
	cbi		PORT_SCK,RFXX_SCK
	cbi		PORT_SEL,RFXX_SEL
	ldi		r16,16
R_W_C1:

	cbi		PORT_SCK,RFXX_SCK
	nop
	nop

	sbrc	r20,7
	sbi		PORT_SDI,RFXX_SDI
	sbrs	r20,7
	cbi		PORT_SDI,RFXX_SDI
	nop
	nop	

	sbi		PORT_SCK,RFXX_SCK
	nop
	nop

	lsl		r19
	rol		r20
	dec		r16
	brne	R_W_C1

	cbi		PORT_SCK,RFXX_SCK
	sbi		PORT_SEL,RFXX_SEL
	pop		r16
ret
;-------------------------------------------------------------------
RF02B_SEND:
	push	r16
	ldi		r16,8
SEND1:
	sbic	PIN_nIRQ,RFXX_nIRQ
	rjmp	SEND1
SEND2:
	sbis	PIN_nIRQ,RFXX_nIRQ
	rjmp	SEND2

	sbrc	r21,7
	rjmp	SEND3
	cbi		PORT_FSK,RFXX_FSK
	rjmp	SEND4
SEND3:
	sbi		PORT_FSK,RFXX_FSK

SEND4:

	lsl		r21
	dec		r16
	brne	SEND1
	pop		r16
ret
;-------------------------------------------------------------------
Rf02_Transmitting:
	ldi		ChkSum,0

	ldi		r19,$39
	ldi		r20,$c0
	rcall	RFXX_WRT_CMD	;enable power amplifier, enable osc, enable synthesizer

	ldi		ChkSum,0

	ldi		r21,$aa
	rcall	RF02B_SEND
	ldi		r21,$aa
	rcall	RF02B_SEND
	ldi		r21,$aa
	rcall	RF02B_SEND
	ldi		r21,$2d
	rcall	RF02B_SEND
	ldi		r21,$d4
	rcall	RF02B_SEND

	ldi 	r21, $F8          ; COMMAND TO SENT
	add		ChkSum,r21
	rcall	RF02B_SEND

	andi 	ChkSum, $0F

	mov		r21,ChkSum
	rcall	RF02B_SEND

	ldi		r21,$aa
	rcall	RF02B_SEND

	ldi		r19,$01
	ldi		r20,$c0
	rcall	RFXX_WRT_CMD	;close ALL

ret
;-------------------------------------------------------------------

.include "WDT.asm"
.include "delays_4M.asm"
