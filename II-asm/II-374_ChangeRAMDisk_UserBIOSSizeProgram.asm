;       ********************************************************
;               CHANGE RAM DISK & USER BIOS SIZE PROGRAM
;       ********************************************************
;
;       NOTE :
;               This sample program is changing RAM disk
;               and User BIOS size.
;
;       <> assemble condition <>
;
;        .Z80
;
;       <> loading address <>
;
			ORG		0100h	;	.PHASE  100h
;
;       <> constant values <>
;
;       BIOS entry
;
WBOOT           EQU     0EB03H          ; Warm Boot entry
CONOUT          EQU     WBOOT   +09H    ; Console out entry
CALLX           EQU     WBOOT   +66H    ; Call extra entry
;
;       System area
;
TOPRAM          EQU     0EF94H          ; Top of User BIOS
BI1LAD          EQU     0EF26H          ; RBIOS1 loading addr
BDSLAD          EQU     0EF24H          ; RBDOS1 loading addr
CCPLAD          EQU     0EF22H          ; CCP loading addr
QTRAMEX         EQU     0EF9DH          ; Quantity of external RAM disk
QTRAMIN         EQU     0EF9CH          ; Quantity of internal RAM disk
USERBIOS        EQU     0EF2DH          ; Size of User BIOS area
YSIZERAM        EQU     0F77AH          ; Size of RAM disk
SIZRAM          EQU     0EF2CH          ; Size of internal RAM disk
DISBNK          EQU     0F52EH          ; Destination bank for CALLX
;
;       Bank value
;
SYSBANK         EQU     0FFH            ; System bank
BANK0           EQU     000H            ; Bank 0 (RAM)
BANK1           EQU     001H            ; Bank 1 (ROM capsel 1)
BANK2           EQU     002H            ; Bank 2 (ROM capsel 2)
;
;       User BIOS area
;
UB_HEAD         EQU     0CBF0H          ; Top addr of User BIOS area's header
UB_OVWRITE      EQU     UB_HEAD +11     ;  Over write flag
UB_RELEASE      EQU     UB_HEAD +12     ;  Release address
;
BIOSENTRY       EQU     00001H          ; CP/M BIOS entry addr
BDOSENTRY       EQU     00006H          ; CP/M BDOS entry addr
;
;       OS ROM jump table
;
CALADRS         EQU     00018H          ; Calculate loading addr
RAMDKMNT        EQU     0001EH          ; RAM disk mount check
MDFYDPB         EQU     00021H          ; Modify disk parameter block
BIOSJTLD        EQU     0001BH          ; BIOS jump table load
;
; New RAM disk size and User BIOSsize
SRAMDISK        EQU     30
SUSERBIOS       EQU     4
MAXSIZE         EQU     142             ; 35.5 KB * 4

;       ********************************************************
;               MAIN PROGRAM
;       ********************************************************
;
;       NOTE :
;               This program is changing size as following.
;                       RAM disk  size --> 30 kbytes
;                       User BIOS size --> 4  kbytes
;
MAIN:
        LD      SP,1000H
        LD      B,SRAMDISK
        LD      C,SUSERBIOS*4
        CALL    CHNGSZ
;
        CALL    MESSAGE
        JP      WBOOT
;
;
;
;       ********************************************************
;               RETURN MESSAGE DISPLAY
;       ********************************************************
;
;       NOTE :
;
;       <> entry parameter <>
;               A  : Message parameter
;       <> return parameter <>
;               NON
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;
MESSAGE:
        LD      HL,MSGTBL       ; Message table top addr.
        ADD     A,A             ; Get target message,
        LD      C,A             ;  A*4     --> C
        LD      B,0             ;  0       --> B
        ADD     HL,BC           ;  HL + BC --> HL
        LD      E,(HL)          ;  (HL)    --> HL
        INC     HL              ; HL is top addr of message.
        LD      D,(HL)          ;
        EX      DE,HL           ;
;
MSGLOOP:
        LD      C,(HL)          ; Get message.
        DEC     C               ; Data is 0?
        INC     C               ;
        RET     Z               ; Yes.
;
        PUSH    HL              ;
        CALL    CONOUT          ; Display message.
        POP     HL              ; 
        INC     HL              ; Pointer update.
        JR      MSGLOOP         ; Loop until find 0.
;
;       Message table
;
MSGTBL:
        DEFW      MSG1            ;
        DEFW      MSG2            ;
        DEFW      MSG3            ;
        DEFW      MSG4            ;
;
;       Message data
;
MSG1:
        DEFB      'Changing size is normaly ending',0DH,0AH,00H
MSG2:
        DEFB      'Parameter error.',0DH,0AH,00H
MSG3:
        DEFB      'User BIOS area cannot destroyed.',0DH,0AH,00H
MSG4:
        DEFB      'Overwrite User BIOS area.',0DH,0AH,00H
;        
;
;       ********************************************************
;               SIZE CHANGING UTILITY
;       ********************************************************
;
;       NOTE :
;
;       <> entry parameter <>
;               B  : New RAM disk  size (unit 1  kbytes)
;               C  : New User BIOS size (unit 256 bytes)
;       <> return parameter <>
;               A  : Return information
;                       =00H -- Normal return
;                       =01H -- Entry parameter is size over
;                       =02H -- Cannot getting User Bios area
;                       =03H -- Overwrite User BIOS area
;       <> preserved registers <>
;               NON
;
;       CAUTION :
;               If new User BIOS size doesn't equal
;               to 0, the programor data in old User
;               BIOS area will be destroyed.
;               If old User BIOS areainhibits over-
;               write by other program, this routine
;               will go back by error return code.
;
CHNGSZ:
        LD      A,(QTRAMEX)     ; Get quantity of external RAM disk.
        OR      A               ; Size is 0?
        JR      Z,IN_RAM        ; Yes.
        LD      B,00H           ; Change new RAM disk size to 0.
IN_RAM:
        LD      A,B             ; Check area size.
        ADD     A,A             ;  Calculate by unit 256 bytes.
        ADD     A,A             ;
        ADD     A,C             ;  Add RAM disk size and User BIOS size.
        CP      MAXSIZE+1       ;  New size is OK?
        LD      A,01H           ;   Return parameter.
        RET     NC              ;  Return if size over.
;
        XOR     A               ; Set return parameter.
        LD      (RET_PRM),A     ;  0 --> RET_PRM
        LD      A,(USERBIOS)    ; Get User BIOS area size.
        OR      A               ; No User BIOS area?
        JR      Z,CHNG_UB       ;  Yes.
;
        CALL    CHK_HEAD        ; Check User BIOS header.
        JR      NZ,CHNG_UB      ;  No User BIOS header.
        LD      A,03H           ; User BIOS already exists.
        LD      (RET_PRM),A     ;  3 --> RET_PRM
        CALL    RELEAS          ; User BIOS area release.
        JR      NC,CHNG_UB      ;  Release OK.
        LD      A,02H           ; Set error return parameter.
        LD      (RET_PRM),A     ;  2 --> RET_PRM
        JR      CHNG_RAM        ;
;
CHNG_UB:
        LD      A,C             ; Change User BIOS area size.
        LD      (USERBIOS),A    ;  New User BIOS area size.
;
CHNG_RAM:
        LD      A,B             ; Change internal RAM disk size.
        LD      (SIZRAM),A      ;  New internal RAM disk size.
;
        LD      A,SYSBANK       ; Set destination bank.
        LD      (DISBNK),A      ;  FFH --> DISBNK
        LD      IX,CALADRS      ; Calculate loading addr.
        CALL    CALLX           ;
;
        LD      (TOPRAM),BC     ; Set new loading addrs.
        LD      (BI1LAD),DE     ;
        LD      (BDSLAD),IX     ;
        LD      (CCPLAD),IY     ;
        INC     DE              ; Set BIOS entry.
        INC     DE              ;
        INC     DE              ;
        LD      (BIOSENTRY),DE  ;
;
        LD      IX,RAMDKMNT+0   ; RAM disk mount check.
        LD      A,(SIZRAM)      ;  Entry parameter. (RAM disk size)
        OR      A               ;  No format
        CALL    CALLX           ;
;
        LD      IX,MDFYDPB      ; Modify disk parameter block.
        CALL    CALLX           ;
        LD      IX,BIOSJTLD     ; BIOS jump table loading.
        CALL    CALLX           ;
;
        LD      A,(RET_PRM)     ; Restore return parameter. (0 or 2)
        RET                     ;
;
;       ********************************************************
;               CHECK USER BIOS HEADER
;       ********************************************************
;
;       NOTE :
;               Check of User BIOS header
;                1. First 2 bytes of header is 'UB'?
;                2. Check sum of header is OK?
;
;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               Z-flag : Return information.
;                       =1 : Header exists.
;                       =0 : Header doesn't exists.
;       <> preserved registers <>
;               BC,DE,HL
;
;       CAUTION :
CHK_HEAD:
        LD      A,(UB_HEAD)     ; User BIOS header check.
        CP      'U'             ;  Header is 'UB'?
        RET     NZ              ;  No.
        LD      A,(UB_HEAD+1)   ;
        CP      'B'             ;
        RET     NZ              ;  No.
;
        PUSH    HL              ; Save registers.
        PUSH    BC              ;
        LD      HL,UB_HEAD      ; Sum check.
        LD      B,16            ;  Header size.
        XOR     A               ;
;
CHK_SUM:
        ADD     A,(HL)          ;  Add header data.
        INC     HL              ;  Next address.
        DJNZ    CHK_SUM         ;  Loop16 times.
;                               ; If result isn't 0,
        OR      A               ;  then non-exists User BIOS.
        POP     BC              ; Restore registers.
        POP     HL              ;
        RET                     ;
;
;       ********************************************************
;               USER BIOS AREA OVERWRITE CHECK
;       ********************************************************
;
;       NOTE :
;               Check overwrite flag in User BIOS area.
;               If overwrite OK, then call release routine
;               and clear header.
;               If overwriting NG, then return with CY on.
;                1. Using SETERR and RSTERR
;                2. Relpacing BDOS error vector
;
;       <> entry parameter <>
;               NON
;       <> return parameter <>
;               CY-flag : Return information.
;                       =0 : Nrmal return
;                       =1 : Cannot overwrite
;       <> preserved registers <>
;               BC,DE,HL
;
;       CAUTION :
;
RELEAS:
        LD      A,(UB_OVWRITE)  ; Check overwrite flag.
        OR      A               ;  Cannot over write?
        SCF                     ;
        RET     Z               ; Yes, then return with carry on.
;
        PUSH    HL              ; Save registers.
        PUSH    DE              ;
        PUSH    BC              ;
        LD      HL,REL_RET      ; Set return address.
        PUSH    HL              ;
        LD      HL,(UB_RELEASE) ; Get release routine addr.
        JP      (HL)            ; Go release routine!
REL_RET:        
        OR      A               ; Carry off.
        POP     BC              ; Restore registers.
        POP     DE              ;
        POP     HL              ;
        RET
;
;       Work area
;
RET_PRM:
        DEFS      1               ; Return parameter area.
        END
