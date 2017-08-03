;;; test.asm -- Testing framework library.


;;;============================================================================
;;; INTERFACE /////////////////////////////////////////////////////////////////
;;;============================================================================

#define TEST_RESULT_PASSED      0
#define TEST_RESULT_FAILED      1

testMain:
        ;; INPUT:
        ;;   <test data> -- determines tests to run
        ;;
        ;; OUTPUT:
        ;;   <screen buffer and LCD> -- results written and flushed
        ;;
        ;; DESCRIPTION:
        ;;   Run loaded tests and display results.
        ;;
        PUSH    BC
        PUSH    DE
        CALL    test_runAll
        CALL    test_displayResults
        CALL    keyboardWait
        POP     DE
        POP     BC
        RET

testLoad:
        ;; INPUT:
        ;;   HL -- NULL-terminated base of array of test routine addresses
        ;;
        ;; OUTPUT:
        ;;   <test data> -- tests in array prepared for running
        ;;
        ;; NOTE: I really do mean `NULL`, not `NUL`: the end of the array
        ;; is marked by a zero address (which does not itself count as a
        ;; test).
        ;;
        LD      (test_array), HL
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

test_runAll:
        ;; INPUT:
        ;;   <test data> -- determines tests to run
        ;;
        ;; OUTPUT:
        ;;   BC -- number of passed tests
        ;;   DE -- number of failed tests
        ;;
        PUSH    HL                    ; STACK: [PC HL]
        PUSH    IX                    ; STACK: [PC HL IX]
        LD      BC, 0                 ; passed tests counter = 0
        LD      DE, 0                 ; failed tests counter = 0
        PUSH    HL                    ; IX = base of array
        POP     IX                    ;
        JR      test_runAll_loopStart ; skip to check at bottom of loop
test_runAll_loop:                     ;
        CALL    test_runAll_jumpHL    ; call routine addressed by HL
        CP      TEST_RESULT_PASSED    ; increment BC if test passed
        JR      NZ, $+3               ;
        INC     BC                    ;
        CP      TEST_RESULT_FAILED    ; increment DE if test failed
        JR      NZ, $+3               ;
        INC     DE                    ;
test_runAll_loopStart:                ;
        LD      A, (IX)               ; HL = (IX); IX += 2
        LD      L, A                  ;
        INC     IX                    ;
        LD      A, (IX)               ;
        LD      H, A                  ;
        INC     IX                    ;
        OR      L                     ; repeat loop if HL nonzero
        JR      NZ, test_runAll_loop  ;
        POP     IX                    ; STACK: [PC HL]
        POP     HL                    ; STACK: [PC]
        RET                           ; return
test_runAll_jumpHL:                   ; (CALL here for `CALL (HL)`)
        JP      (HL)                  ;

test_displayResults:
        PUSH    HL                    ; STACK: [PC HL]
        CALL    terminalClear         ; clear terminal
        CALL    terminalCursorHome    ; bring cursor home
        LD      HL, test_headerString ; print header
        CALL    terminalPrintString   ;
        LD      HL, test_passedString ; print passed string and number
        CALL    terminalPrintString   ;
        LD      L, C                  ;
        LD      H, B                  ;
        CALL    terminalPrint16Bit    ;
        CALL    terminalNewLine       ;
        LD      HL, test_failedString ; print failed string and number
        CALL    terminalPrintString   ;
        LD      L, E                  ;
        LD      H, D                  ;
        CALL    terminalPrint16Bit    ;
        CALL    terminalNewLine       ;
        LD      HL, test_totalString  ; print total string and number
        CALL    terminalPrintString   ;
        LD      L, E                  ;
        LD      H, D                  ;
        ADD     HL, BC                ;
        CALL    terminalPrint16Bit    ;
        POP     HL                    ; STACK: [PC]
        RET                           ; return

;;;============================================================================
;;; CONSTANT DATA /////////////////////////////////////////////////////////////
;;;============================================================================

test_headerString:
        .db     "Test Results\n"
        .db     "================"
        .db     0
test_passedString:
        .db     " Passed: "
        .db     0
test_failedString:
        .db     " Failed: "
        .db     0
test_totalString:
        .db     "  Total: "
        .db     0

;;;============================================================================
;;; VARIABLE DATA /////////////////////////////////////////////////////////////
;;;============================================================================

#define test_array      testData + 0
#define TEST_DATA_SIZE  2
