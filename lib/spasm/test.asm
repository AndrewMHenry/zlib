;;; test.asm -- Testing framework library.


;;;============================================================================
;;; INTERFACE /////////////////////////////////////////////////////////////////
;;;============================================================================

testMain:
        PUSH    HL
        LD      HL, fontSBF
        CALL    writeSetFont
        CALL    test_displayResults
        CALL    keyboardWait
        POP     HL
        RET

;;;============================================================================
;;; SETUP AND TEARDOWN ////////////////////////////////////////////////////////
;;;============================================================================

testInit:
        RET

testExit:
        RET


;;;============================================================================
;;; HELPER FUNCTIONS //////////////////////////////////////////////////////////
;;;============================================================================

test_displayResults:
        PUSH    DE
        PUSH    HL
        LD      DE, 0                ;
        LD      HL, test_lines
        CALL    test_writeLines
        CALL    screenUpdate
        POP     HL
        POP     DE
        RET
;;         LD      HL, test_titleString ;
;;         CALL    writeString          ;
;;         LD      D, 8
;;         LD      B, 16
;; test_displayResults_lineLoop:
;;         LD      A, '='
;;         CALL    writeCharacter
;;         LD      A, E
;;         ADD     A, 6
;;         LD      E, A
;;         DJNZ    test_displayResults_lineLoop
;;         CALL    screenUpdate
;;         CALL    keyboardWait
;;         POP     HL
;;         POP     DE
;;         POP     BC
;;         RET

;;;============================================================================
;;; HELPER ROUTINES ///////////////////////////////////////////////////////////
;;;============================================================================

test_writeStrings:
        ;; INPUT:
        ;;   B -- number of strings in array
        ;;   DE -- location of first character of first string
        ;;   HL -- base of array of string bases
        ;;
        ;; OUTPUT:
        ;;   <screen buffer> -- strings written on successive lines
        ;;
        PUSH    BC
        PUSH    DE
        PUSH    HL
        PUSH    IX
test_writeStrings_loop:
        DJNZ    test_writeStrings_loop
        POP     IX
        POP     HL
        POP     DE
        POP     BC
        RET

test_writeLines:
        PUSH    BC
        PUSH    DE
        PUSH    HL
test_writeLines_outerLoop:
        LD      A, (HL)
        OR      A
        JR      Z, test_writeLines_return
test_writeLines_innerLoop:
        CALL    writeCharacter
        LD      A, E
        ADD     A, 6
        LD      E, A
        INC     HL
        LD      A, (HL)
        OR      A
        JR      NZ, test_writeLines_innerLoop
        LD      A, D
        ADD     A, 8
        LD      D, A
        LD      E, 0
        INC     HL
        JR      test_writeLines_outerLoop
test_writeLines_return:
        POP     HL
        POP     DE
        POP     BC
        RET

;;;============================================================================
;;; CONSTANT DATA /////////////////////////////////////////////////////////////
;;;============================================================================

#define TEST_NUM_STRINGS        5

test_strings:
        .dw     test_titleString
        .dw     test_equalString
        .dw     test_passedString
        .dw     test_failedString
        .dw     test_totalString

test_lines:
test_titleString:
        .db     "Test Results", 0
test_equalString:
        .db     "================", 0
test_passedString:
        .db     " Passed:", 0
test_failedString:
        .db     " Failed:", 0
test_totalString:
        .db     "  Total:", 0
        .db     0

;;;============================================================================
;;; VARIABLE DATA /////////////////////////////////////////////////////////////
;;;============================================================================

#define TEST_DATA_SIZE 0
