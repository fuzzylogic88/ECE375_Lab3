;***********************************************************
;*					  Lab 3, ECE 375
;*
;*			Authors: Daniel Green & Gregory Kane
;*		With code from BasicBumpBot.asm (Zier, Sinky, Lee)
;*				  Date modified: 2-6-2025
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is required for LCD Driver
.def	n = r17					; used in loop to contain target value
.def	ctr = r18				; used in loop to contain current value
.def	waitcnt = r19			; register to contain WTime 
.def	mprB = r23				; temp storage for scrolling text
.def	ilcnt = r24				; Inner Loop Counter
.def	olcnt = r25				; Outer Loop Counter

.equ	clear = 4				; Clear LCD button
.equ	scroll = 7				; Scroll LCD text button
.equ	names = 5				; Name display button
.equ	WTime = 25				; Wait loop time (25*0.01s->250ms)

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0056					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:

		; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr
		ldi		mpr, high(RAMEND)
		out		SPH, mpr

		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State

		; Initialize LCD Display
		rcall LCDInit	
		rcall LCDBacklightOn
		rcall LCDClr

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:

		; Move strings from Program Memory to Data Memory
		; Line 1: $0100 -> $010F
		; Line 2: $0110 -> $011F
	
		in		mpr, PIND								; load button states into mpr
		andi	mpr, (1<<clear | 1<<scroll | 1<<names)	; clear all bits except those we're interested in

		sbrs mpr, clear		; skip next if clear bit in mpr is 1
		rcall CLEARSCR		; clear display

		sbrs mpr, names		; skip if names bit in mpr is 1
		rcall DISPLAYNAMES	; otherwise, display text

		sbrs mpr, scroll	; skip if scroll bit in mpr is 1
		rcall SCROLLTEXT	; scroll all displayed text by 1 char

		rjmp MAIN

CLEARSCR:
	rcall LCDClr
	rjmp MAIN

DISPLAYNAMES:

		; FIRST LINE PREP
		ldi ZL, low(STRING_A_BEG<<1)	; prime ZL with low byte of string
		ldi ZH, high(STRING_A_BEG<<1)	; prime ZH with high byte of string
		ldi YL, $00						; prime YL with low byte of LCD space
		ldi YH, $01						; prime YH with high byte of LCD space

		ldi n, $10 ; 16 bytes per string
		clr ctr

LINE1:
		; FIRST LINE WRITE
		lpm mpr, Z	; load data present in ZL/ZH into r16
		st Y, mpr	; move data in r16 into LCD space

		inc ZL		; increment low byte of Z register
		inc YL		; increment low byte of Y (LCD) register (0100->0101,0102...)

		inc ctr		
		cp ctr, n
		brne LINE1	; If we've not transferred 16 bytes, go to top of loop

		; SECOND LINE PREP
		;----------------------------------------------------
		ldi ZL, low(STRING_C_BEG<<1)	; prime ZL with low byte of 2nd string
		ldi ZH, high(STRING_C_BEG<<1)	; prime ZH with high byte of 2nd string
		clr ctr							; clear the counter since we're gonna loop again
		;----------------------------------------------------

LINE2:
		; SECOND LINE WRITE
		lpm mpr, Z	; load data present in ZL/ZH into r16
		st Y, mpr	; move data in r16 into LCD space
	
		inc YL		; increment low bytes of both Y and Z regs
		inc ZL		;
		inc ctr
		cp ctr, n

		brne LINE2

rcall LCDWrite ; push data in LCD storage to the screen
rjmp MAIN

; shift all the bytes in the LCD buffer over once and add 250ms delay
SCROLLTEXT:
		ldi	waitcnt, WTime				; load wait duration into waitctr register
		ldi YL, $00						; prime YL with low byte of LCD space
		ldi YH, $01						; prime YH with high byte of LCD space

		ldi n, $1F						; 32 bytes to shift
		clr ctr							; reset our counter
		clr mprB						; clear tmp buffer

		ld mpr, Y						; load first visible char into mpr

SCROLL_LOOP:									
		ldi ZL, $1F						; these two lines preserve the final visible char 
		ldi ZH, $01						;
		ld r15, Z						; store final char in r15

		inc YL							; move to 2nd char
		ld mprB, Y						; save current char to 2nd buffer
		st Y, mpr						; commit 1st char to 2nd char position
		mov mpr, mprB					; move data in mprB (current char) to mpr

		ldi ZL, $00						; prime YH and YL with start location of LCD data 
		ldi ZH, $01						;
		st Z, r15						; write final char into first char position

		inc ctr							; continue looping until we've transferred all the characters
		cp ctr, n						
		brne SCROLL_LOOP

rcall LCDWrite							; push udpated data in LCD storage to the screen
rcall Wait								; wait required 250mS before returning to Main
rjmp MAIN


; Wait loop from BasicBumpBot.asm (Zier, Sinky, Lee)
;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly
;		waitcnt*10ms.  Just initialize wait for the specific amount
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			(((((3*ilcnt)-1+4)*olcnt)-1+4)*waitcnt)-1+16
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt			; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt			; Decrement wait
		brne	Loop			; Continue Wait loop

		pop		olcnt			; Restore olcnt register
		pop		ilcnt			; Restore ilcnt register
		pop		waitcnt			; Restore wait register
		ret						; Return from subroutine


;***********************************************************
;*	Stored Program Data
;***********************************************************

STRING_BEG:
.DB		" My Test String "		; Declaring data in ProgMem
STRING_END:

STRING_A_BEG:
.DB		"   My Name is   "			
STRING_A_END:

STRING_B_BEG:
.DB		"    Jane Doe    "				
STRING_B_END:

STRING_C_BEG:
.DB		"  Daniel Green  "			
STRING_C_END:

STRING_D_BEG:
.DB		"  Gregory Kane  "			
STRING_D_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
