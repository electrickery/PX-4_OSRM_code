;	***************************************************
;		1 M BIT ROM READ PROGRAM
;	***************************************************
;
;	NOTE :
;		This sample program is reading 1 Mbit ROM.
;		and displaying the data.
;
;	<> assemble condition <>
;
	.Z80
;
;	<> loading address <>
;
	.PHASE 100H
;
;	<> constant values <>
;
;	BIOS entry
;
WBOOT		EQU	0EB03H		; Warm Boot entry
CONIN		EQU	WBOOT + 06H	; Console input entry
CONOUT		EQU	WBOOT + 09H	; Console out entry
;
;	System area
;
LSCRVRAM	EQU	0F294H		; VRAM top address.
;	
STOP		EQU	03H
CR		EQU	0DH
LF		EQU	0AH
CLS		EQU	0CH
ESC		EQU	1BH
SPACE		EQU	20H
;
P90		EQU	90H		; I/O port 91H
P91		EQU	91H		; I/O port 91H
P92		EQU	92H		; I/O port 92H
P93		EQU	93H		; I/O port 93H
P94		EQU	94H		; I/O port 94H
;
;	***************************************************
;		MAIN PROGRAM
;	***************************************************
;
;	NOTE :
;		This program is reading 1 Mbit ROM,
;		and displaying kanji font.
;
MAIN:
	LD	SP,1000H	; Set stack pointer.
;
	CALL	CHKROM		; Connect external RAM disk?
	JP	C,WBOOT		; No.
;
	CALL	CURSOFF		; Cursor off.
MAIN10:
	LD	C,CLS		; Clear screen & home.
	CALL	CONOUT		; 
;
	LD	HL,(LSCRVRAM)	; VRAM top addr --> HL
	LD	B,4		; Loop counter (4 lines)
;
MAIN20:
	PUSH	HL		; Save registers.
	PUSH	BC		; 
	LD	B,15		; Loop counter (15 characters)
MAIN30:
	PUSH	HL		; Save registers.
	PUSH	BC		; 
	LD	B,16		; Loop counter (16 dot lines)
;
MAIN40:
	CALL	READROM		; Read 1 Mbit ROM.
	CALL	WRTVRAM		; Write the data to VRAM directly.
;
	INC	HL		; VRAM pointer increment.
	CALL	READROM		; Read 1 Mbit ROM.
	CALL	WRTVRAM		; Write the data to VRAM directly.
;
	LD	DE,31		; Get next dot line address in VRAM.
	ADD	HL,DE		; 
	DJNZ	MAIN40		; Loop.
;
	POP	BC		; Restore registers.
	POP	HL		; 
	INC	HL		; Get nect column address in VRAM.
	INC	HL		; 
	DJNZ	MAIN30		; 
;
	POP	BC		; Restore registers.
	POP	HL		; 
	LD	DE,32*16	; Get next line address in VRAM.
	ADD	HL,DE		; 
	DJNZ	MAIN20		; Loop.
;
	CALL	CONIN		; Key input wait.
	CP	STOP		; STOP key?
	JR	NZ,MAIN10	; No.
;
	CALL	CURSON		; Cursor on.
	JP	WBOOT		; End.

;	***************************************************
;		READ DATA FROM 1 M BIT ROM
;	***************************************************
;
;	NOTE :
;		Read a data from 1 Mbit ROM.
;		This routine uses the function of auto
;		increment.
;
;	<> entry parameter <>
;		NON
;	<> return parameter <>
;		A	Read data
;	<> preserved registers <>
;		NON
;
;	CAUTION :
READROM:
	LD	A,(P90DT)	; Last 8 bits data.
	INC	A		; 256 bytes read?
	LD	(P90DT),A	;  Set the new address.
	JR	NZ,READ50	; No.
;
	LD	A,(P91DT)	; Middle 8 bits.
	INC	A		; 256*256 bytes read?
	LD	(P91DT),A	;  Set the new address.
	JR	NZ,READ40	; No.
;
	LD	A,(P92DT)	; Top 8 bits data.
	INC	A		; Count up.
	LD	(P92DT),A	; Set the new address.
;
READ40:
	LD	A,(P90DT)	; I/O port output for setting next address.
	OUT	(P90),A		;  Last 8 bits.
	LD	A,(P91DT)	; 
	OUT	(P91),A		; Middle 8 bits.
	LD	A,(P92DT)	; 
	OUT	(P92),A		; Top 8 bits.
;
READ50:
	IN	A,(P93)		; Read ROM data.
	RET			; 
;
;	***************************************************
;		CHECK CONNECTING EXTERNAL RAM DISK
;	***************************************************
;
;	NOTE :
;
;	<> entry parameter <>
;		NON
;	<> return parameter <>
;		CY : Return information.
;		   =0 -- Connected RAM disk.
;		   =1 -- Not connected RAM disk.
;	<> preserved registers <>
;		NON
;
;	CAUTION :
;
CHKROM:
	IN	A,(P94)		; Get external status.
	RLA			; MSB --> CY
	RET			; 
;
;		WRITE VRAM AT THE HL ADDRESS.
;
WRTVRAM:
	LD	(HL),A
	RET
;
;		CURSOR ON
;
CURSON:
	LD	C,ESC
	CALL	CONOUT
	LD	C,'3'
	CALL	CONOUT
	RET
;
;		CURSOR OFF
CURSOFF:
	LD	C,ESC
	CALL	CONOUT
	LD	C,'2'
	CALL	CONOUT
	RET
;
;
P90DT:
	DB	0FFH
P91DT:
	DB	0FFH
P92DT:
	DB	001H
;
	END
