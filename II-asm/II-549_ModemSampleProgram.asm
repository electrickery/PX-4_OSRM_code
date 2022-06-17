;	*******************************************************
;		MODEM SAMPLE PROGRAM 
;	*******************************************************
;
;	NOTE:
;		This sample program is for using MODEM
;		cartridge.
;
;	<> assemble condition <>
	.Z80
;	
;	<>loading address <>
;
	.PHASE	100H
;
;	<> constant values <>
;
;	IO registers
ZSWR		EQU	18H		; Switch register
ZCSW1		EQU	02H		;  Cartridge switch 1
ZCSW0		EQU	01H		;  Cartridge switch 2
ZIOCTRL		EQU	19h		; IO control register
BZCRS		EQU	3		;  CRS signal bit
;
;	System area
RZSWR		EQU	0F0005H		; SWR data setting area
RZIOCTRL	EQU	0F0006H		; IOCTRL data setting area
CRGDEV		EQU	0F53FH		; Cartridge device code
;
;	BIOS entry (RBIOS2)
WBOOT		EQU	0EB03H		; Warm Boot
RSIOX		EQU	WBOOT	+51H	; Serial Input/Output
CONST		EQU	WBOOT	+03H	; Console status
CONIN		EQU	WBOOT	+06H	; Console in
CONOUT		EQU	WBOOT	+09H	; Console out
;
;	RSIOX parameter
RSOPN		EQU	10H		; Open code
RSCLS		EQU	20H		; Close code
RSIST		EQU	30H		; Input status code
RSOST		EQU	40H		; Output status code
RSGET		EQU	50H		; Get code
RSPUT		EQU	60H		; Put code
;
RS232		EQU	01H		; RS-232 using
SIO		EQU	02H		; SIO using
CSIO		EQU	03H		; Cartridge SIO using
;
;	Cartridge mode.
;
DBMODE		EQU	00000000B	; DB mode
HSMODE		EQU	01000000B	; HS mode
IOMODE		EQU	10000000B	; IO mode
OTMODE		EQU	11000000B	; OT mode
;
DVMDM		EQU	00001111B	; Device code for Modem
;
CR		EQU	0DH		; Carrage return.
LF		EQU	0AH		; Line feed.
;
RCVSZ		EQU	200H		; Receive buffer size
;
;	*************************************************
;		MAIN PROGRAM
;	*************************************************
;
;	NOTE ;
;
;	CAUTION :
;		If you use resident BIOS, change
;		RBIOS1 to RBIOS2.
;		If Your program is ROM execute program,
;		you must use RBOIS2.
;
START:
	JP	PSTART
;
;	Message
;
MSG1:	DB	'Start of Modem communication.',CR,LF,00H
MSG2:	DB	'Modem cartridge check.',CR,LF,00H
MSG3:	DB	'Send initial data.',CR,LF,00H
MSG4:	DB	'Receive anwser code.',CR,LF,00H
MSG5:	DB	'!!! Start of Modem !!!',CR,LF,00H
MSG6:	DB	'!!! End of Modem !!!',CR,LF,00H
MSG7:	DB	'Communication error',CR,LF,00H
;
;
;	Main program
;
PSTART
	LD	SP,4000H	; Set stack pointer
	LD	HL,MSG1		; 'Start of Modem communication'
	CALL	MSGDSP		; Message display
;
	LD	HL,MSG2		; 'Modem cartridge check'
	CALL	MSGDSP		; Message display
	LD	A,(CRGDEV)	; Get cartridge device code.
	LD	B,A		; Moden cartridge?
	AND	03H		; Get device code only.
	JP	NZ,WBOOT	; No, then WBOOT.
	LD	A,B		; Restore CRGDEV.
	CP	IOMODE+DVMVM	; Already IO mode? (10000000B + 00001111B)
	CALL	NZ,SETMODE	; No, then set into IO mode.
;
CRESET:
	CALL	CRST02		; CRS line on and wait 10 msec.
	CALL	CRST01		; CRS line off and wait 10 msec.
;
	LD	HL,OPNDAT	; Copy RSIOX open parameters.
	LD	DE,OPNPRM	; 
	LD	BC,9		; 
	LDIR			;
;
	LD	HL,OPNPRM	; RSIOX open.
	LD	B,RSOPN+CSIO	; Using Cartridge SIO. 10H + 03H
	OR	A		; Already opened?
	JP	NZ,ERREND	; Yes.
;
PUTINIT:
	LD	HL,MSG3		; 'Send initial data.
	CALL	MSGDSP		; Display message.
;
	LD	HL,OPNPRM	; Send initial data.
	LD	A,(INITDATA)	;  Initial data --> A
	LD	C,A		; 
	LD	B,RSPUT		;  Using PUT function of RSIOX.
	CALL	RSIOX		; 
	JR	NZ, ERREND	;  Error return, then retry.
;
GETANS:
	LD	HL,MSG4		; 'Receive answer code.'
	CALL	MSGDSP		; Display message.
;
GETANS1:
	LD	HL,OPNPRM	; Receive answer code.
	LD	B,RSGET		;  Using GET function of RSIOX.
	CALL	RSIOX		; 
	JP	NZ,ERREND	;  Error return, then Warm boot.
;
	CALL	CHARDSP		; Display receiving character.
	CP	CR		; Receive char. is CR?
	JR	NZ,GETANS1	; No. (Loop until receiving CR code.)
;
	LD	B,RSCLS		; Close RSIOX.
	CALL	RSIOX		; 
	LD	BL,MSG5		; '!!! Start of modem !!!'
	CALL	MSGDSP		; Display message.
;
	LD	HL,MDMDAT	; Copy initial data parameter for RSIOX.
	LD	DE,OPNPRN	; 
	LD	BC,9		;
	LDIR			;
	LD	HL,OPNPRM	; Open RSIOX.
	LD	B,RSOPN+CSIO	;  Using OPEN function of RSIOX. 10H + 03H
	CALL	RSIOX		; 
	OR	A		; Error return?
	JP	NZ,ERREND	; Yes. (then Warm boot)
;
KEYCHK:
	CALL	CONST		; Get console status.
	INC	A		; Exist inputing key data?
	JR	Z,PUT		; Yes.
;
	LD	HL,OPNPRM	; Get console status.
	LD	B,RSIST		;  Using INSTS function of RSIST.
	CALL	RSIOX		;  
	INC	A		; Exist receiving data?
	JR	Z,GET		; Yes.
	HALT			; 
	JR	KEYCHK		; Loop to Key Check.
;
PUT:
	CALL	CONIN		; Get inputed key code.
	CP	03H		; STOP key?
	JR	Z,PEND		; Yes.
	CALL	CHARDISP	; Display inputed key data.
;
	LD	HL,OPNPRM	; Send inputed key data.
	LD	C,A		; 
	LD	B,RSPUT		;  Using PUT function of RSIOX.
	CALL	RSIOX		; 
	JR	KEYCHK		; Loop to Key Check.
;
GET:
	LD	HL,OPNPRM	; Get receiving data.
	LD	B,RSGET		;  Using GET function of RSIOX.
	CALL	RSIOX		; 
	CALL	CHARDSP		; Display receiving data.
	JR	KEYCHK		; Loop to Key Check.
;
ERREND:
	LD	HL,MSG7		; 'Communication error.'
	CALL	MSGDSP		; Display message.
PEND:
	LD	HL,MSG6		; '!!! End of modem !!!'
	CALL	MSGDSP		; Display message.
	LD	HL,CLSCMD	; Modem close parameter --> HL
	CALL	PUTDATA		; Send modem close parameter.
;
	LD	B,RSCLS		; Close RSIOX.
	CALL	RSIOX		; 
	JP	WBOOT		; Jump to Warm boot.
;
;
;	*************************************************
;		SELECT IO MODE
;	*************************************************
;
;	NOTE :
;		Select IO mode (Cartridge mode)
;
;	<> entry parameter <>
;		NON
;	<> return parameter <>
;		NON
;	<>preserved registers <>
;		NON
;
SETMODE:
	LD	A,(RZSWR)		; Get switch register data.
	AND	OFFH-ZCSW1-ZCSW0	; Clear CSW1,0 bit.
	OR	ZCSW0			; Set IO mode.
	LD	(RZSWR),A		; Store to memory.
	OUT	(ZSWR),A		; Output to IO port.
	RET				;
;
;	*************************************************
;		CRS LINE CONTROL SUBROUTINE
;	*************************************************
;
;	NOTE :
;		There are two routine, one is setting
;		CSR high, and one is setting CRS low.
;
;	<> entry parameter <>
;		NON
;	<> return parameter <>
;		NON
;	<> preserved registers <>
;		NON
;
CRSTO1:
	LD	A,(RZIOCTLR)	; Get IO control register data.
	SET	BZCRS,A		; Set CRS high.
	JR	CRST		; 
CRST02:
	LD	A,(RZIOCTLR)	; Get IO control register data.
	RES	BZCRS,A		; Reset CRS low.
CRST:
	LD	A,(RZIOCTLR)	; Store data to memory.
	OUT	(ZIOCTLR),A	; Out put to IO port.
	CALL	WAIT10		; Wait about 10 msec.
	RET			; 
;
;	*************************************************
;		SEND DATA TO RSIOX
;	*************************************************
;
;	NOTE :
;		Send data to RSIOX until finding
;		00h code.
;
;	<> entry parameter <>
;		HL : Data top address.
;	<> return parameter <>
;		NON
;	<>preserved registers <>
;		NON
;
;	CAUTION :
;		If error happened, then stop this
;		this program.
PUTDATA:
	LD	C,(HL)		; Get sending data. (1 byte)
	INC	C		; 
	DEC	C		; Data is 00h?
	RET	Z		; Yes. (then return)
	PUSH	HL		; Save parameter.
	LD	HL,OPNPRM	; Send data to RSIOX;
	CALL	RSIOX		; 
	POP	HL		; Restore parameter.
	INC	HL		; Pointer update.
	JR	PUTDATA		; Loop.
;
;	*************************************************
;		DISPLAY MESSAGE UNTIL FIND 00H
;	*************************************************
;
;	NOTE :
;
;	<> entry parameter <>
;		HL : Message top address.
;	<> return parameter <>
;		NON
;	<> preserved registers <>
;		NON
;
;	CAUTION :
MSGDSP:
	LD	C,(HL)		; Get displaying data.
	INC	C		; 
	DEC	C		; Getting data is 00h?
	RET	Z		; Yes. (then return)
;
	PUSH	HL		; Save parameter.
	CALL	CONOUT		; Console out data.
	POP	HL		; Restore parameter.
	INC	HL		; Update parameter.
	JR	MSGDSP		; Loop.
;
;	*************************************************
;		DISPLAY A CHARACTER
;	*************************************************
;
;	NOTE : 
;
;	<> entry parameter <>
;		A : Character code.
;	   return parameter <>
;		NON
;	<> preserved registers <>
;		All registers.
;
;	CAUTION :
;		If character code is CR, then console
;		out CR with LF.
CHARDSP:
	PUSH	AF		; Save all registers.
	PUSH	BC		; 
	PUSH	DE		; 
	PUSH	HL		; 
	PUSH 	AF		;
	LD	C,A		; Console out data.
	CALL	CONOUT		; 
	POP	AF		; Get inputed parameter.
	CP	CR		; Is it CR?
	LD	C.LF		; If so, then console out LF.
	CALL	Z,CONOUT	;
	POP	HL		; Restore all registers.
	POP	DE		; 
	POP	BC		; 
	POP	AF		; 
	RET			; 
;
;	*************************************************
;		WAIT ABOUT 100 MILI SECOND
;	*************************************************
;
;	NOTE :
;
;	<> entry parameter <>
;		NON
;	<> return paramter <>
;		NON
;	<> preserved registers <>
;		NON
;
;	CAUTION :
;
WAIT10:
	LD	BC,2		; 
	PUSH	AF		; 
WT10:
	LD	A,230		; 
WT20:
	DEC	A		; 
	JR	NZ,WT20		;
;
	DEC	BC		; 
	LD	A,B		;
	OR	C		; 
	JR	NZ,WT10		; 
	POP	AF		; 
	RET			; 
;
;	Constant data & work area
;
CLSCWD:
	DB	'%Z',CR,00H	; Modem close command data.
;
;	RSIOX first open parameter.
;
OPNDAT:
	DW	RCVBUF		; Receive buffer top address.
	DW	RCVSZ		; Receive buffer size.
	DB	006H		; Baud rate. (300 bps)
	DB	003H		; Bit length (8 bits/character)
	DB	000H		; Parity (non parity)
	DB	001H		; Stop bit (1 stop bit)
	DB	0FFH		; Special parameter.
;
;	Modem initial data.
;		(8 bits, non parity, 1 stop bit)
INITDATA:
	DB	01011000B
;
;	RSIOX second open parameter.
;		(This parameters are matched with initial data.)
MDMDAT:
	DW	RCVBUF		; Receive buffer top address.
	DW	RCVSZ		; Receive buffer size.
	DB	006H		; Baud rate.
	DB	003H		; Bit length.
	DB	000H		; Parity.
	DB	001H		; Stop bit.
	DB	0FFH		; Special parameter.
;
;	RSIOX parameter area (for calling & return)
;
OPNPRM:
	DS	9
;
;	Receiving buffer area.
;
RCVBUF:
	DS	RCVSZ
;
	END

