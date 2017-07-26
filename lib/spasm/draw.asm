;;;==========================================================================;;;
;;; DEFINITIONS //////////////////////////////////////////////////////////// ;;;
;;;==========================================================================;;;

#define drawDataEnd     drawData
#define DRAW_DATA_SIZE  0


;;;==========================================================================;;;
;;; INTERFACE ////////////////////////////////////////////////////////////// ;;;
;;;==========================================================================;;;

drawInit:
        ;; INPUT:
        ;;   <none>
        ;;
        ;; OUTPUT:
        ;;   <draw data initialized>
        ;;
        ;; EVEN THOUGH THIS ROUTINE CURRENTLY DOES NOTHING, calling it is
        ;; formally required to guarantee correct library behavior.  This
        ;; is to ensure that programs which rely on this library are not
        ;; broken if library initialization is required in the future.
        ;;
        ;; Because this library depends on the ``screen'' library, this
        ;; routine must be called AFTER ``screenInit''.
        ;;
        RET


drawExit:
        RET


drawRectangle:
        ;; INPUT:
        ;;   B -- pixelwise height of rectangle
        ;;   C -- pixelwise widht of rectangle
        ;;   D -- pixelwise (top) row of rectangle
        ;;   E -- pixelwise (left) column of rectangle
        ;;
        ;; OUTPUT:
        ;;   <rectangular outline written to screen buffer>
        ;;
        PUSH    DE                    ; STACK: [PC DE]
        CALL    drawLineX             ; top side
        CALL    drawLineY             ; left side
        LD      A, D                  ; bottom side
        ADD     A, B                  ;
        DEC     A                     ;
        LD      D, A                  ;
        CALL    drawLineX             ;
        LD      A, D                  ; right side
        SUB     B                     ;
        INC     A                     ;
        LD      D, A                  ;
        LD      A, E                  ;
        ADD     A, C                  ;
        DEC     A                     ;
        LD      E, A                  ;
        CALL    drawLineY             ;
        POP     DE                    ; STACK: [PC]
        RET                           ; return


drawLineX:
        ;; INPUT:
        ;;   C -- pixelwise length of line
        ;;   D -- pixelwise row of line
        ;;   E -- pixelwise (left) column of line
        ;;
        ;;
        ;; first mask: 2^(8-c%8)-1 = 2*(2^(7-c%8))-1 = 2*decode((~c)&7)-1
        ;; last mask: 2^8 - 2^(8-((c+w-1)%8+1)) = -decode((-(c+w))&7)
        ;;
        PUSH    BC                     ; STACK: [PC]
        PUSH    HL                     ; STACK: [PC HL]
        LD      B, 1                   ; touch affected area
        CALL    screenTouchRectangle   ;
        CALL    draw_getBufferAddress  ; HL = first buffer address
        CALL    draw_getWidthBytewise  ; B = bytewise width of line
        LD      B, A                   ;
        CALL    draw_getByteMaskRight  ; C = right byte mask
        LD      C, A                   ;
        CALL    draw_getByteMaskLeft   ; ACC = left byte mask
drawLineX_loop:                        ;
        DJNZ    $+3                    ; AND in mask last iteration
        AND     C                      ;
        INC     B                      ;
        OR      (HL)                   ; OR in ACC
        LD      (HL), A                ;
        INC     HL                     ; next byte
        LD      A, 0FFh                ; ACC = all ones for next time
        DJNZ    drawLineX_loop         ; repeat until counter 0
        POP     HL                     ; STACK: [PC BC]
        POP     BC                     ; STACK: [PC]
        RET                            ; return


drawLineY:
        ;; INPUT:
        ;;   B -- pixelwise length of line
        ;;   D -- pixelwise (top) row of line
        ;;   E -- pixelwise column of line
        ;;
        ;; OUTPUT:
        ;;   <vertical line drawn to screen buffer>
        ;;
        PUSH    BC                   ; STACK: [PC BC]
        PUSH    DE                   ; STACK: [PC BC DE]
        PUSH    HL                   ; STACK: [PC BC DE HL]
        LD      C, 1                 ; touch affected area
        CALL    screenTouchRectangle ;
        CALL    getBufferAddress     ; HL = first buffer address
        LD      A, E                 ; C = byte
        CPL                          ;
        AND     007h                 ;
        CALL    decodeByte           ;
        LD      C, A                 ;
        LD      DE, 12               ; DE = offset to next buffer row
drawLineY_loop:                      ;
        LD      A, (HL)              ; apply byte to buffer
        OR      C                    ;
        LD      (HL), A              ;
        ADD     HL, DE               ; move on to next row
        DJNZ    drawLineY_loop       ; repeat for each pixel
        POP     HL                   ; STACK: [PC BC DE]
        POP     DE                   ; STACK: [PC BC]
        POP     BC                   ; STACK: [PC]
        RET                          ; return


drawClearRectangle:
        ;; INPUT:
        ;;   B -- pixelwise height of rectangle
        ;;   C -- pixelwise width of rectangle
        ;;   D -- pixelwise (top) row of rectangle
        ;;   E -- pixelwise (left) column of rectangle
        ;;
        ;; OUTPUT:
        ;;   <rectangular area forced clear>
        ;;
        PUSH    BC                      ; STACK: [PC BC]
        PUSH    DE                      ; STACK: [PC BC DE]
drawClearRectangle_loop:                ;
        CALL    drawClearLineX          ; clear line at current row
        INC     D                       ; move to next row
        DJNZ    drawClearRectangle_loop ; repeat for each row
        POP     DE                      ; STACK: [PC BC]
        POP     BC                      ; STACK: [PC]
        RET                             ; return


drawClearLineX:
        ;; INPUT:
        ;;   C -- pixelwise length of line
        ;;   D -- pixelwise row of line
        ;;   E -- pixelwise (left) column of line
        ;;
        ;; OUTPUT:
        ;;   <line forced clear>
        ;;
        PUSH    BC                            ; STACK: [PC BC]
        PUSH    HL                            ; STACK: [PC BC HL]
        CALL    draw_getBufferAddress         ; HL = first buffer address
        CALL    draw_getWidthBytewise         ; B = bytewise width
        LD      B, A                          ;
        CALL    draw_getByteMaskRight         ; C = ~right mask
        CPL                                   ;
        LD      C, A                          ;
        CALL    draw_getByteMaskLeft          ; ACC = ~left mask
        CPL                                   ;
drawClearLineX_loop:                          ;
        DJNZ    $+3                           ; if last iteration:
        OR      C                             ;     OR in right mask
        INC     B                             ;
        AND     (HL)                          ; AND ACC into buffer byte
        LD      (HL), A                       ;
        INC     HL                            ; point HL to next buffer byte
        XOR     A                             ; ACC = 0 for next time
        DJNZ    drawClearLineX_loop           ; repeat loop
        POP     HL                            ; STACK: [PC BC]
        POP     BC                            ; STACK: [PC]
        RET                                   ; return
        

drawClearScreen:
        ;; INPUT:
        ;;   <none>
        ;;
        ;; OUTPUT:
        ;;   <entire screen forced clear>
        ;;
        ;; This routine is functionally a special case of ``drawClearRectangle''
        ;; above, but its implementation is much simpler and this case is very
        ;; common.
        ;;
        PUSH    BC                   ; STACK: [PC BC]
        PUSH    DE                   ; STACK: [PC BC DE]
        PUSH    HL                   ; STACK: [PC BC DE HL]
        LD      HL, screenBuffer     ; HL = buffer
        LD      DE, screenBuffer + 1 ; DE = buffer + 1
        LD      BC, 767              ; BC = size - 1
        LD      (HL), 0              ; "seed" first byte
        LDIR                         ; propagate
        LD      DE, 0                ; touch rectangle covering screen
        LD      BC, 64*256+96        ;
        CALL    screenTouchRectangle ;
        POP     HL                   ; STACK: [PC BC DE]
        POP     DE                   ; STACK: [PC BC]
        POP     BC                   ; STACK: [PC]
        RET                          ; return


drawEraseRectangular:
        ;; INPUT:
        ;;   B -- pixelwise height of region
        ;;   C -- pixelwise width of region (
        ;;   D -- pixelwise (top) row of region
        ;;   E -- pixelwise (left) column of region
        ;;
        ;; OUTPUT:
        ;;
        PUSH    BC
        PUSH    DE
        PUSH    HL
        CALL    getBufferAddress
        LD      A, E
        CPL
        AND     007h
        CALL    decodeByte
        ADD     A, A
        NEG
drawMaskRectangularLoop:
        LD      A, (HL)
        AND     D
        LD      (HL), A
        INC     HL
        LD      A, (HL)
        AND     E
        LD      (HL), A
        LD      A, B
        LD      B, 0
        ADD     HL, BC
        LD      B, A
        DJNZ    drawMaskRectangularLoop
        POP     HL
        POP     DE
        POP     BC
        RET


;;;==========================================================================;;;
;;; IMAGERY ROUTINES /////////////////////////////////////////////////////// ;;;
;;;==========================================================================;;;
        
drawPicture:
        ;; INPUT:
        ;;   B -- pixelwise height of sprite
        ;;   D -- pixelwise (top) row for sprite
        ;;   E -- pixelwise (left) column for sprite
        ;;   HL -- base of picture data
        ;;
        ;; OUTPUT:
        ;;   (screenBuffer) -- updated to reflect picture
        ;;   <screen data> -- affected rectangle touched
        ;;
        PUSH    BC                     ; STACK: [PC BC]
        PUSH    DE                     ; STACK: [PC BC DE]
        PUSH    HL                     ; STACK: [PC BC DE HL]
        PUSH    IX                     ; STACK: [PC BC DE HL IX]
        PUSH    HL                     ; STACK: [PC BC DE HL IX HL]
        LD      C, 8                   ; touch affected area
        CALL    screenTouchRectangle   ;
        CALL    getBufferAddress       ; HL = buffer address
        LD      A, E                   ; E = ACC = (~E) % 8
        CPL                            ;
        AND     007h                   ;
        LD      E, A                   ;
        CALL    decodeByte             ; C = mask byte
        DEC     A                      ;
        ADD     A, A                   ;
        INC     A                      ;
        LD      C, A                   ;
        LD      IX, drawPictureRotates ; point IX to rotate code
        LD      D, 0                   ;
        ADD     IX, DE                 ;
        POP     DE                     ; STACK: [PC BC DE HL IX]
drawPictureLoop:                       ;
        PUSH    BC                     ; STACK: [PC BC DE HL IX BC]
        LD      A, (DE)                ; ACC = picture byte
        INC     DE                     ; advance DE to next picture byte
        JP      (IX)                   ; rotate byte
drawPictureRotates:                    ;
        RRCA                           ;
        RRCA                           ;
        RRCA                           ;
        RRCA                           ;
        RRCA                           ;
        RRCA                           ;
        RRCA                           ;
        LD      B, A                   ; B = rotated byte
        AND     C                      ; apply byte AND mask to buffer
        OR      (HL)                   ;
        LD      (HL), A                ;
        INC     HL                     ; move to next buffer byte
        LD      A, C                   ; apply byte AND ~mask to buffer
        CPL                            ;
        AND     B                      ;
        OR      (HL)                   ;
        LD      (HL), A                ;
        LD      BC, 11                 ; move HL to next row
        ADD     HL, BC                 ;
        POP     BC                     ; STACK: [PC BC DE HL IX]
        DJNZ    drawPictureLoop        ; repeat loop
        POP     IX                     ; STACK: [PC BC DE HL]
        POP     HL                     ; STACK: [PC BC DE]
        POP     DE                     ; STACK: [PC BC]
        POP     BC                     ; STACK: [PC]
        RET                            ; return


drawSprite:
        ;; INPUT:
        ;;   B -- pixelwise height of sprite
        ;;   D -- pixelwise (top) row for sprite
        ;;   E -- pixelwise (left) column for sprite
        ;;   HL -- base of picture data
        ;;   IX -- base of mask data
        ;;
        ;; OUTPUT:
        ;;   <sprite drawn to buffer>
        ;;
        ;; 
        PUSH    BC                   ; STACK: [PC BC]
        PUSH    DE                   ; STACK: [PC BC DE]
        PUSH    HL                   ; STACK: [PC BC DE HL]
        PUSH    IX                   ; STACK: [PC BC DE HL IX]
        LD      C, 8                 ; touch affected area
        CALL    screenTouchRectangle ;
        CALL    getBufferAddress     ; HL = buffer address
        LD      IX, drawSpriteRotates ; point IX to rotates
        LD      A, E                  ;
        CPL                           ;
        AND     007h                  ;
        LD      E, A                  ;
        ADD     A, A                  ;
        ADD     A, E                  ;
        LD      D, 0                  ;
        ADD     IX, DE                ;
drawSpriteLoop:                      ;
        JP      (IX)                 ; rotate both bytes
drawSpriteRotates:                   ;
        RRC     C                    ;
        RRCA                         ;
        RRC     C                    ;
        RRCA                         ;
        RRC     C                    ;
        RRCA                         ;
        RRC     C                    ;
        RRCA                         ;
        RRC     C                    ;
        RRCA                         ;
        RRC     C                    ;
        RRCA                         ;
        RRC     C                    ;
        RRCA                         ;
        ADD     HL, DE               ;
        DJNZ    drawSpriteLoop       ;
        POP     IX                   ;
        POP     HL                   ;
        POP     DE                   ;
        POP     BC                   ;
        RET                          ;


;;;==================;;;
;;; UTILITY ROUTINES ;;;
;;;==================;;;

draw_decodeByte:
decodeByte:
        ;; INPUT:
        ;;   ACC -- encoded number (0-7, inclusive)
        ;;
        ;; OUTPUT:
        ;;   ACC -- decoded number (2^input)
        ;;
        ;; If I write enough routines similar to this one, maybe they should
        ;; go in their own library.
        ;;
        PUSH    DE                   ; STACK: [PC DE]
        PUSH    HL                   ; STACK: [PC DE HL]
        LD      HL, decodeByteTable  ; HL = base of table
        LD      E, A                 ; DE = ACC
        LD      D, 0                 ;
        ADD     HL, DE               ; point HL to decoded byte
        LD      A, (HL)              ; ACC = decoded byte
        POP     HL                   ; STACK: [PC DE]
        POP     DE                   ; STACK: [PC]
        RET                          ; return
        ;;
draw_decodeByte_table:
decodeByteTable:
        .db     00000001b            ; 1 << 0
        .db     00000010b            ; 1 << 1
        .db     00000100b            ; 1 << 2
        .db     00001000b            ; 1 << 3
        .db     00010000b            ; 1 << 4
        .db     00100000b            ; 1 << 5
        .db     01000000b            ; 1 << 6
        .db     10000000b            ; 1 << 7


draw_getBufferAddress:
getBufferAddress:
        ;; INPUT:
        ;;   D -- pixelwise row
        ;;   E -- pixelwise column
        ;;
        ;; OUTPUT:
        ;;   HL -- buffer address
        ;;
        PUSH    BC                 ; STACK: [PC BC]
        LD      A, D               ; ACC = 4 * row
        ADD     A, A               ;
        ADD     A, A               ;
        LD      L, A               ; BC = HL = 4 * row
        LD      H, 0               ;
        LD      C, L               ;
        LD      B, H               ;
        ADD     HL, HL             ; HL = 8 * row
        ADD     HL, BC             ; HL = 12 * row
        LD      A, E               ; BC = ACC = column // 8
        RRCA                       ;
        RRCA                       ;
        RRCA                       ;
        AND     00011111b          ;
        LD      C, A               ;
        LD      B, 0               ;
        ADD     HL, BC             ; HL = 12 * row + column // 8
        LD      BC, screenBuffer   ; HL = buffer + 12 * row + column // 8
        ADD     HL, BC             ;
        POP     BC                 ; STACK: [PC]
        RET                        ; return


draw_getWidthBytewise:
        ;; INPUT:
        ;;   C -- pixelwise width of rectangular region
        ;;   E -- pixelwise (left) column of rectangular region
        ;;
        ;; OUTPUT:
        ;;   ACC -- bytewise width of rectangular region
        ;;
        ;; By ``bytewise width'', we mean the number of byte-wide columns
        ;; with which the rectangular region intersects, NOT just the number
        ;; of times 8 goes into the width.  Two different rectangles of the
        ;; same pixelwise width can differ in bytewise width by starting in
        ;; different columns.
        ;;
        LD      A, E                 ; ACC = column % 8 + width - 1
        AND     007h                 ;
        ADD     A, C                 ;
        DEC     A                    ;
        RRCA                         ; ACC >>= 3 (ACC //= 8)
        RRCA                         ;
        RRCA                         ;
        AND     01Fh                 ;
        INC     A                    ; ACC += 1
        RET                          ; return


draw_getByteMaskLeft:
        ;; INPUT:
        ;;   E -- pixelwise (left) column of rectangular region
        ;;
        ;; OUTPUT:
        ;;   ACC -- left-side byte mask
        ;;
        LD      A, E                 ; ACC = first byte mask
        CPL                          ;
        AND     007h                 ;
        CALL    decodeByte           ;
        DEC     A                    ;
        ADD     A, A                 ;
        INC     A                    ;
        RET                          ; return


draw_getByteMaskRight:
        ;; INPUT:
        ;;   C -- pixelwise width of rectangular region
        ;;   E -- pixelwise (left) column of rectangular region
        ;;
        ;; OUTPUT:
        ;;   ACC -- right-side byte mask
        ;;
        LD      A, E                 ; ACC = -(2^((-width-column)%8))
        ADD     A, C                 ;
        NEG                          ;
        AND     007h                 ;
        CALL    decodeByte           ;
        NEG                          ;
        RET                          ; return
