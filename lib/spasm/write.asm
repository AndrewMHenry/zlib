;;; write.asm -- Library for writing text on the screen.

;;;==========================================================================;;;
;;; DEFINITIONS //////////////////////////////////////////////////////////// ;;;
;;;==========================================================================;;;

#define writeFontDimensions     writeData + 0
#define writeFontArray          writeFontDimensions + 2
#define writeDataEnd            writeFontArray + 2
#define WRITE_DATA_SIZE         4

;;;==========================================================================;;;
;;; INTERFACE ////////////////////////////////////////////////////////////// ;;;
;;;==========================================================================;;;

writeInit:
        ;; INPUT:
        ;;   <none>
        ;;
        ;; OUTPUT:
        ;;   <write library initialized>
        ;;
        ;; Writing text is NOT GUARANTEED TO WORK until a font is set with
        ;; writeSetFont below.
        ;;
        RET


writeExit:
        RET


writeSetFont:
        ;; INPUT:
        ;;   HL -- base of font data
        ;;
        ;; OUTPUT:
        ;;   <font initialized in library>
        ;;
        PUSH    BC                        ; STACK: [PC BC]
        PUSH    HL                        ; STACK: [PC BC HL]
        LD      C, (HL)                   ; BC = dimensions, HL = array base
        INC     HL                        ;
        LD      B, (HL)                   ;
        INC     HL                        ;
        LD      (writeFontDimensions), BC ; (writeFontDimensiosn) = dimensions
        LD      (writeFontArray), HL      ; (writeFontBase) = array base
        POP     HL                        ; STACK: [PC BC]
        POP     BC                        ; STACK: [PC]
        RET                               ; return


writeCharacter:
        ;; INPUT:
        ;;   ACC -- character to write
        ;;   D -- pixelwise top row for glyph
        ;;   E -- pixelwise left column for glyph
        ;;   <write data>
        ;;
        ;; OUTPUT:
        ;;   <character drawn to buffer>
        ;;
        PUSH    BC              ; STACK: [PC BC]
        PUSH    HL              ; STACK: [PC BC HL]
        CALL    write_getGlyph  ; B, C, HL = height, width, picture
        CALL    drawPicture     ; draw picture
        POP     HL              ; STACK: [PC BC]
        POP     BC              ; STACK: [PC]
        RET                     ; return


writeString:
        ;; INPUT:
        ;;   HL -- pointer to NUL-terminated string
        ;;   <write data>
        ;;
        ;; OUTPUT:
        ;;   <string drawn to buffer>
        ;;
        LD      A, (HL)             ; ACC = first character
        OR      A                   ; return if NUL
        RET     Z                   ;
        PUSH    BC                  ; STACK: [PC BC]
        PUSH    DE                  ; STACK: [PC BC DE]
        PUSH    HL                  ; STACK: [PC BC DE HL]
writeStringLoop:                    ;
        PUSH    HL                  ; STACK: [PC BC DE HL HL]
        CALL    write_getGlyph      ; B, C, HL = height, width, picture
        CALL    drawPicture         ; draw the picture
        POP     HL                  ; STACK: [PC BC DE HL]
        LD      A, E                ; advance E to next column
        ADD     A, C                ;
        LD      E, A                ;
        INC     HL                  ; advance HL to next character
        LD      A, (HL)             ; ACC = next character
        OR      A                   ; repeat if character not NUL
        JR      NZ, writeStringLoop ;
        POP     HL                  ; STACK: [PC BC DE]
        POP     DE                  ; STACK: [PC BC]
        POP     BC                  ; STACK: [PC]
        RET                         ; return


;;;==========================================================================;;;
;;; SUPPORT ROUTINES /////////////////////////////////////////////////////// ;;;
;;;==========================================================================;;;

write_getGlyph:
        ;; INPUT:
        ;;   ACC -- character whose glyph data to retrieve
        ;;   <write data> -- (used to determine glyph)
        ;;
        ;; OUTPUT:
        ;;   B -- pixelwise height of glyph
        ;;   C -- pixelwise width of glyph
        ;;   HL -- picture for glyph
        ;;
        LD      HL, (writeFontArray)
        ADD     A, A
        LD      C, A
        LD      B, 0
        ADD     HL, BC
        LD      A, (HL)
        INC     HL
        LD      H, (HL)
        LD      L, A
        LD      BC, (writeFontDimensions)
        RET
