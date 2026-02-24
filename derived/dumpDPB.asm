;
;  6.2.3 System Area II (RSYSAR2), II-613 - 

Disk Parameter Block (at 0F200h, II-629)
;
WBOOT   EQU     0EB03H          ; Warm Boot entry
CONIN           EQU     WBOOT   +06H
CONOUT          EQU     WBOOT   +09H    ; Console out entry

DPB0    EQU     0F200h  ; DPB (Disk Parameter Block) for RAM disk A:
DPB1    EQU     0F20Fh  ; DPB (Disk Parameter Block) for ROM capsule 1, B:
DPB2    EQU     0F21Eh  ; DPB (Disk Parameter Block) for ROM capsule 2, C:
DPB3    EQU     0F22Dh  ; DPB (Disk Parameter Block) for FDD, D:, E:, F:, G:
;DPB4    EQU     0F23Ch
;DPB5    EQU     0F24Bh
;DPB6    EQU     0F25Ah
DPB7    EQU     0F2CFh  ; DPB (Disk Parameter Block) for MCT, H: (microcassette)
DPB8    EQU     0F24Bh  ; DPB (Disk Parameter Block) for ROM cartridge 1, J:
DPB9    EQU     0F25Ah  ; DPB (Disk Parameter Block) for ROM cartridge 2, K:
DPB10   EQU     0F296h  ; DPB (Disk Parameter Block) for RAM cartridge, I:

DPB_SIZ EQU     15

I_SPT   EQU     00h; + 01h
I_BSFT  EQU     02h
I_BMASK EQU     03h
I_EXMSK EQU     04h
I_MABN  EQU     05h; + 06h
I_NDIRE EQU     07h; + 08h
I_BAB1  EQU     09h
I_BAB2  EQU     0Ah
I_NBCB  EQU     0Bh; + 0Ch
I_NTBD  EQU     0Dh; + 0Eh

CR      EQU     0DH
LF      EQU     0AH
STOP    EQU     03H

        ORG     0100h
        
MAIN:
        LD      SP, 01000h
        
        LD      IY, DPB0
        CALL    DMPDPB
        CALL    CONIN
        
        LD      IY, DPB1
        CALL    DMPDPB
        CALL    CONIN
        
        LD      IY, DPB2
        CALL    DMPDPB
        CALL    CONIN
        
        LD      IY, DPB3
        CALL    DMPDPB
        CALL    CONIN
       
        LD      IY, DPB7
        CALL    DMPDPB
        CALL    CONIN
       
        LD      IY, DPB8
        CALL    DMPDPB
        CALL    CONIN
       
        LD      IY, DPB9
        CALL    DMPDPB
        CALL    CONIN
       
        LD      IY, DPB10
        CALL    DMPDPB
        CALL    CONIN
       
        CALL    CONIN
        JP      WBOOT
        
NIB2HEX:
        AND     00Fh
        ADD     A, '0'
        CP      '9' + 1
        JR      C,N2H1
        ADD     A, 7
N2H1:        
        RET
        
BIN2HEX:
        PUSH    AF
        RRC     A
        RRC     A
        RRC     A
        RRC     A
        AND     00Fh
        CALL    NIB2HEX
        LD      C, A
        CALL    CONOUTS
        
        POP     AF
        AND     00Fh
        CALL    NIB2HEX
        LD      C, A
        CALL    CONOUTS
        
        RET
        
BIN4HEX:
        LD      A, H
        CALL    BIN2HEX
        LD      A, L
        CALL    BIN2HEX
        RET

BIN2BIN:
        JR      BIN2HEX


;       DPB address in IY
DMPDPB:
        CALL    CRLF
        LD      (DPB_BASE), IY
        LD      HL, (DPB_BASE)
        CALL    BIN4HEX

        LD      HL, MSG_DPBE
        CALL    MSG_DSP
        CALL    CRLF
        
        LD      L, (IY+I_SPT)
        LD      H, (IY+I_SPT+1)
        CALL    BIN4HEX
        LD      HL, MSG_SPT
        CALL    MSG_DSP
        CALL    CRLF
        
        CALL    SPACE
        CALL    SPACE
        LD      C, (IY+I_BSFT)
        CALL    BIN2HEX
        LD      HL, MSG_BSFT
        CALL    MSG_DSP
        CALL    CRLF
        
        CALL    SPACE
        CALL    SPACE
        LD      C, (IY+I_BMASK)
        CALL    BIN2HEX
        LD      HL, MSG_BMASK
        CALL    MSG_DSP
        CALL    CRLF
        
        CALL    SPACE
        CALL    SPACE
        LD      C, (IY+I_EXMSK)
        CALL    BIN2HEX
        LD      HL, MSG_EXMSK
        CALL    MSG_DSP
        CALL    CRLF
        
        LD      L, (IY+I_MABN)
        LD      H, (IY+I_MABN+1)
        CALL    BIN4HEX
        LD      HL, MSG_MABN
        CALL    MSG_DSP
        CALL    CRLF
        
        LD      L, (IY+I_NDIRE)
        LD      H, (IY+I_NDIRE+1)
        CALL    BIN4HEX
        LD      HL, MSG_NDIRE
        CALL    MSG_DSP
        CALL    CRLF
        
        CALL    SPACE
        CALL    SPACE
        LD      C, (IY+I_BAB1)
        CALL    BIN2BIN
        LD      HL, MSG_BAB1
        CALL    MSG_DSP
        CALL    CRLF
        
        CALL    SPACE
        CALL    SPACE
        LD      C, (IY+I_BAB2)
        CALL    BIN2BIN
        LD      HL, MSG_BAB2
        CALL    MSG_DSP
        CALL    CRLF
        
        LD      C, (IY+I_NBCB)
        CALL    BIN4HEX
        LD      HL, MSG_NBCB
        CALL    MSG_DSP
        CALL    CRLF
        
        LD      C, (IY+I_NTBD)
        CALL    BIN4HEX
        LD      HL, MSG_NTBD
        CALL    MSG_DSP
        CALL    CRLF
        
        RET
        
CONOUTS:
        PUSH    AF
        PUSH    BC
        PUSH    DE
        PUSH    HL
        CALL    CONOUT
        POP     HL
        POP     DE
        POP     BC
        POP     AF
        RET
        
MSG_DSP:        
        LD      A,(HL)
        OR      A
        RET     Z
;
        LD      C,A
        PUSH    HL
        CALL    CONOUT
        POP     HL
        INC     HL
        JR      MSG_DSP
        
CRLF:
        PUSH    BC
        LD      C,CR            ; Carriage return.
        CALL    CONOUTS          ;
        LD      C,LF            ; Line feed.
        CALL    CONOUTS          ;
        POP     BC
        RET
;
SPACE:
        PUSH    BC
        LD      C,' '            ; Line feed.
        CALL    CONOUTS          ;
        POP     BC
        RET


DPB_BASE:       DEFW    0000        

DPB_SPT:        DEFW    26          ; Sectors per track
DPB_BSFT:       DEFB    3           ; Block shift
DPB_BMASK:      DEFB    7           ; Block mask
DPB_EXMSK:      DEFB    3           ; Extend mask
DPB_MABN:       DEFW    242         ; Max. allocation block number
DPB_NDIRE:      DEFW    63          ; Number of directory entries
DPB_BAB1:       DEFB    1100$0000B  ; Bit map for allocation blocks 1
DPB_BAB2:       DEFB    0000$0000B  ; Bit map for allocation blocks 2
DPB_NBCB:       DEFW    16          ; No. of tracks before directory
DPB_NTBD:       DEFW    2           ; Disk Parameter Block address

MSG_SPT:        DEFB    'h Sectors per track', 0
MSG_BSFT:       DEFB    'h Block shift', 0
MSG_BMASK:      DEFB    'h Block mask', 0
MSG_EXMSK:      DEFB    'h Extend mask', 0
MSG_MABN:       DEFB    'h Max. allocation block number', 0
MSG_NDIRE:      DEFB    'h Number of directory entries', 0
MSG_BAB1:       DEFB    'h Bit map for allocation blocks 1', 0
MSG_BAB2:       DEFB    'h Bit map for allocation blocks 2', 0
MSG_NBCB:       DEFB    'h No. of bytes in dir. check buffer', 0
MSG_NTBD:       DEFB    'h No. of tracks before directory', 0
MSG_DPBE:       DEFB    'h Disk Parameter Block address', 0

;BS  BM  ABS
; 3   7  1024
; 4  15  2048
; 5  31  4096
; 6  63  8192
; 7 127 16384
