;;;============================================================================
;;; INTERFACE  ////////////////////////////////////////////////////////////////
;;;============================================================================

terminalPrintString:
        ;; INPUT:
        ;;   HL -- start of null-terminated string to print
        ;;   <terminal data> -- determines where to print the string
        ;;
        ;; OUTPUT:
        ;;   <screen buffer, LCD> -- string written and flushed at current
        ;;       terminal cursor position
        ;;   <terminal data> -- cursor position updated
        ;;
        LD      A, (HL)
        OR      A
        RET     Z
        PUSH    HL
terminalPrintString_loop:
        CALL    terminalPrintCharacter
        INC     HL
        LD      A, (HL)
        OR      A
        JR      NZ, terminalPrintString_loop
        POP     HL
        RET

terminalPrintCharacter:
        ;; INPUT:
        ;;   ACC -- character to print
        ;;   <terminal data> -- determines where to print the character
        ;;
        ;; OUTPUT:
        ;;   <screen buffer, LCD> -- character written and flushed at current
        ;;       terminal cursor position
        ;;   <terminal data> -- cursor position updated
        ;;
        CP      '\n'
        JP      Z, terminalNewLine
        PUSH    BC
        PUSH    DE
        LD      C, A
        CALL    terminal_unpackCursor
        CALL    terminal_getPixelwiseLocation
        LD      A, C
        CALL    writeCharacter
        CALL    screenUpdate
        LD      A, (terminal_cursor)
        INC     A
        LD      (terminal_cursor), A
        POP     DE
        POP     BC
        RET

terminalPrint16Bit:
        ;; INPUT:
        ;;   HL -- unsigned 16-bit integer to print
        ;;
        ;; OUTPUT:
        ;;   <screen buffer and LCD> -- integer written and flushed
        ;;
        PUSH    DE
        PUSH    HL
        LD      DE, -10000
        LD      A, '0' - 1
terminalPrint16Bit_loop10000:
        INC     A
        ADD     HL, DE
        JR      C, terminalPrint16Bit_loop10000
        SBC     HL, DE
        CALL    terminalPrintCharacter
        LD      DE, -1000
        LD      A, '0' - 1
terminalPrint16Bit_loop1000:
        INC     A
        ADD     HL, DE
        JR      C, terminalPrint16Bit_loop1000
        SBC     HL, DE
        CALL    terminalPrintCharacter
        LD      A, L
        LD      H, '0' - 1
terminalPrint16Bit_loop100:
        INC     H
        SUB     100
        JR      NC, terminalPrint16Bit_loop100
        ADD     A, 100
        LD      L, A
        LD      A, H
        CALL    terminalPrintCharacter
        LD      A, L
        LD      H, '0' - 1
terminalPrint16Bit_loop10:
        INC     H
        SUB     10
        JR      NC, terminalPrint16Bit_loop10
        ADD     A, 10
        LD      L, A
        LD      A, H
        CALL    terminalPrintCharacter
        LD      A, L
        ADD     A, '0'
        CALL    terminalPrintCharacter
        POP     HL
        POP     DE
        RET

terminalCursorHome:
        ;; INPUT:
        ;;   <none>
        ;;
        ;; OUTPUT:
        ;;   <terminal data> -- cursor positioned at top left corner of screen
        ;;
        XOR     A
        LD      (terminal_cursor), A
        RET

terminalClear:
        ;; INPUT:
        ;;   <none>
        ;;
        ;; OUTPUT:
        ;;   <screen buffer, LCD> -- cleared
        ;;
        CALL    drawClearScreen
        CALL    screenUpdate
        RET

;;;============================================================================
;;; VARIABLE DATA /////////////////////////////////////////////////////////////
;;;============================================================================

#define terminal_cursor         terminalData + 0
#define TERMINAL_DATA_SIZE      1

;;;============================================================================
;;; SETUP AND TEARDOWN ////////////////////////////////////////////////////////
;;;============================================================================

terminalInit:
        PUSH    HL
        LD      HL, fontSBF
        CALL    writeSetFont
        POP     HL
        RET

terminalExit:
        RET


;;;============================================================================
;;; HELPER ROUTINES ///////////////////////////////////////////////////////////
;;;============================================================================

terminal_unpackCursor:
        ;; INPUT:
        ;;   (terminal_cursor) -- current cursor position
        ;;
        ;; OUTPUT:
        ;;   D -- current cursor row
        ;;   E -- current cursor column
        ;;
        LD      A, (terminal_cursor)
        LD      D, A
        AND     $0F
        LD      E, A
        LD      A, D
        RRCA
        RRCA
        RRCA
        RRCA
        AND     $07
        LD      D, A
        RET

terminal_getPixelwiseLocation:
        ;; INPUT:
        ;;   D -- cell-wise row
        ;;   E -- cell-wise column
        ;;
        ;; OUTPUT:
        ;;   D -- pixel-wise row
        ;;   E -- pixel-wise column
        ;;
        LD      A, D
        ADD     A, A
        ADD     A, A
        ADD     A, A
        LD      D, A
        LD      A, E
        ADD     A, A
        ADD     A, E
        ADD     A, A
        LD      E, A
        RET

terminalNewLine:
        ;; INPUT:
        ;;   (terminal_cursor) -- initial cursor position
        ;;
        ;; OUTPUT:
        ;;   (terminal_cursor) -- new cursor position (start of next line)
        ;;
        LD      A, (terminal_cursor)
        ADD     A, $10
        AND     A, $F0
        LD      (terminal_cursor), A
        RET
