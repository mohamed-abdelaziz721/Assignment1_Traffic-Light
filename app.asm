$NOMOD51	 ;to suppress the pre-defined addresses by keil
$include (C8051F020.INC)		; to declare the device peripherals	with it's addresses
ORG 0H					   ; to start writing the code from the base 0


;diable the watch dog
MOV WDTCN,#11011110B ;0DEH
MOV WDTCN,#10101101B ;0ADH

; config of clock
MOV OSCICN , #14H ; 2MH clock
;config cross bar
MOV XBR0 , #00H
MOV XBR1 , #00H
MOV XBR2 , #040H  ; Cross bar enabled , weak Pull-up enabled 


;config,setup
MOV P0MDOUT, #00h   ; input
MOV P1MDOUT, #0FFh  ;output
MOV P2MDOUT, #0FFh
MOV P3MDOUT, #0FFh
MOV R0,#3      ; second 7 segment count from 3 , 2, 1, 0  as default
MOV R1,#3      
MOV P2, #01H

MAX EQU 10
; NOW EQU	3
MIN EQU 0

INIT:	
		MOV R4,#10         
		MOV DPTR, #400h
		MOV A,#10
		CLR C
		SUBB A,R0           ; 10 - 3 = 7 is the offset of DPTR (start from 3) 
		MOVC A,@A+DPTR		; A is  the offset of DPTR (start from 3)  indirect addressing on programm space LUT
		MOV P1,A			
		AJMP COUNT


;loop

START: 	MOV R4,#10
		MOV DPTR, #400h
		AJMP COUNT

MAIN:

	DJNZ R4, COUNT               ;decreament R4 jump to "count" in a loop untill R4 is zero ( 9, 8,7..........0)
	DJNZ R0, INIT				 ;decreament R0 jump to "INIT" in a loop untill R0 is zero ( deafalut 3,2,1,0)	
	ACALL LED_TOGGLE             ; when R0 is zero toggle the leds
	LED_TOGGLE_END:
	AJMP RESTART
	END_COUNT:
	; ACALL DELAY
	ACALL SWITCHS
	; old place
	
	AJMP MAIN

LED_TOGGLE:	CLR A
			MOV A, P2
			CJNE A, #01H, RED_ON        ; compare acc to 0000 0001 if not equal  jump to RED_ON
			RED_ON_END:
			ACALL GREEN_ON              ; if the red was on then open the GREEN
RET

RED_ON:	MOV P2,#01H
		AJMP LED_TOGGLE_END     		; return to main to restart the counter

GREEN_ON:	MOV P2, #02H
RET

RESTART:	
	MOV A,R1          			; move R1 value to Acc   "R1 & R2 " are responsible of count down 
	MOV R0, A					; move acc to R0
	AJMP INIT					; Re-Inistialize

SWITCHS:

	CLR A
	MOV A, P0           		; get P0 status to chech if any switch is pushed -- contineu if first pin is active 
	ANL A, #00000001B   		; and with 00000001B to check "fast freq button" on P0.0
	JNZ FAST					; if and is zero continue, if not zero "Jump to Fast"
	MOV A, P0					;continue if second pin is not active -- get P0 status to chech if "Meduim" switch is pushed
	ANL A, #00000010B			; and with 00000010B to check "Meduim freq button" on P0.1
	JNZ MEDIUM					; if and is zero continue, if not zero "Jump to Fast"
	MOV A, P0					;continue if third pin is not active -- get P0 status to chech if "Meduim" switch is pushed
	ANL A, #00000100B			; and with  00000100B to check "slow freq button" on P0.2
	JNZ SLOW					; if and is zero continue, if not zero "Jump to Fast"
	ACALL DELAY         		; Default "Delay" if no freq is choosen 
	X:                  		; label used to continue buttons check "Inc or Dec" after jump to any "freq" from the last step   
		MOV A, P0       		;continue if forth pin is not active -- get P0 status to chech if "Meduim" switch is pushed
		ANL A, #00001000B		; and with 00001000B  to check "Meduim freq button" on P0.3
		JZ INCRENENT			; ?? JZ vs JNZ   Jump to "INCREMENT" if zero "push button"  
		MOV A, P0               ;continue if second pin is not active -- get P0 status to chech if "Meduim" switch is pushed
		ANL A, #00010000B		;and with 00001000B  to check "Meduim freq button" on P0.3
		JZ DECREMENT			;Jump to "DECREMENT" if zero "push button"
	RET


SLOW:
	; MOV A, SLOW_FREQ
	; MOV SPEED, A
	ACALL DELAY3                 ; call delay 3 to slow the count down 
	AJMP X						 ; Jump back to X to contineu switch checking
MEDIUM:
	; MOV A, MEDIUM_FREQ
	; MOV SPEED, A
	ACALL DELAY2				  ; call delay 2 to slow the count down 
	AJMP X						  ;Jump back to X to contineu switch checking
FAST:
	; MOV A, FAST_FREQ
	; MOV SPEED, A
	ACALL DELAY1				 ; call delay 2 to slow the count down 
	AJMP X						 ;Jump back to X to contineu switch checking
INCRENENT:
	; MOV R7, #NOW
	CJNE R1, #MAX, Y            ; compare R1 to the max value "if not equal jump to Y"  "If equal contineue & restart"
	AJMP RESTART				; Restart the cycle and Toggle the  red and green leds 
	Y:
		INC R1                  ; Increase R1  
		AJMP RESTART			; Jump to Restart	
	RET
DECREMENT:                      ; Same As Increament
	; MOV R7, NOW
	CJNE R1, #MIN, Z
	AJMP RESTART
	Z:
		DEC R1
		AJMP RESTART
	RET

COUNT:	CLR A                    ; clear the acc 
		MOVC A,@A+DPTR	         ; offset DPTR to start counting the first 7 - seg from 9
		MOV P3,A		         ; use what is in the LUT to light up the 7 - seg
		INC DPTR				 ; Inc the DPTR  9,8,7.....,0 one at each step 
		AJMP END_COUNT			 ; End-count in the main followed by "switch Check " and "main loop to count down the max value"

DELAY:                           ; Each delay correspond to a certain freq "depending on R7 value"
	MOV R7,#10
	LOOP3:MOV R6,#200
	LOOP2:MOV R5,#198
	LOOP1:DJNZ R5,LOOP1
	DJNZ R6,LOOP2
	DJNZ R7,LOOP3
	RET

DELAY1:
	MOV R7,#5
	LOOP4:MOV R6,#200
	LOOP5:MOV R5,#198
	LOOP6:DJNZ R5,LOOP6
	DJNZ R6,LOOP5
	DJNZ R7,LOOP4
	RET

DELAY2:
	MOV R7,#10
	LOOP7:MOV R6,#200
	LOOP8:MOV R5,#198
	LOOP9:DJNZ R5,LOOP9
	DJNZ R6,LOOP8
	DJNZ R7,LOOP7
	RET

DELAY3:
	MOV R7,#15
	LOOP10:MOV R6,#200
	LOOP11:MOV R5,#198
	LOOP12:DJNZ R5,LOOP12
	DJNZ R6,LOOP11
	DJNZ R7,LOOP10
	RET

ORG 400H
DB 6FH,7FH,07H,7DH,6DH,66H,4FH,5BH,06H,3FH
  ; 9 ,8, ...........................,1,0	
END