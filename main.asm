;***********************************************************
;*	This is the skeleton file for Lab 3 of ECE 375
;*
;*	 Author: Daniel Green & Gregory Kane
;*	   Date: 1-31-2025
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is required for LCD Driver

.def	sum = r17				; iterator for loop
.def	n = r18
.def	str_start = r24			; string start address
.def	str_dest = r23			; string destination address

.equ	string_a_len = 10
.equ	string_b_len = 8
.equ	string_c_len = 12
.equ	string_d_len = 12

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
INIT:							; The initialization routine

		; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr
		ldi		mpr, high(RAMEND)
		out		SPH, mpr

		; Initialize LCD Display
		CALL LCDInit	
		CALL LCDBacklightOn
		CALL LCDClr

		; NOTE that there is no RET or RJMP from INIT,
		; this is because the next instruction executed is the
		; first instruction of the main program

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program

		; Move strings from Program Memory to Data Memory
		; Line 1: $0100 -> $010F
		; Line 2: $0110 -> $011F
		clr n
		ld str_start, STRING_A_BEG
		rcall Loop


		; Display the strings on the LCD Display
		
		rcall LCDWrite

		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

LOOP: 
		add sum, n
		lpm str_dest, str_start
		inc str_start, 1
		inc n
		cpi n, 16
		brlt loop

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
		; Save variables by pushing them to the stack

		; Execute the function here

		; Restore variables by popping them from the stack,
		; in reverse order

		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING_BEG:
.DB		" My Test String "		; Declaring data in ProgMem
STRING_END:

STRING_A_BEG:
.DB		"   My Name is   "			; 10 chars
STRING_A_END:

STRING_B_BEG:
.DB		"    Jane Doe    "				; 8 chars
STRING_B_END:

STRING_C_BEG:
.DB		"  Daniel Green  "			; 12 chars
STRING_C_END:

STRING_D_BEG:
.DB		"  Gregory Kane  "			; 12 chars
STRING_D_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
