;;; test.asm -- Testing framework library.


;;;============================================================================
;;; INTERFACE /////////////////////////////////////////////////////////////////
;;;============================================================================

testMain:
        PUSH    HL
        LD      HL, 0
        LD      (curRow), HL
        LD      HL, test_titleString
        CALL    test_putString
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

test_putString:
        PUSH    BC
        PUSH    DE
        PUSH    HL
        JR      test_putString_skip
test_putString_loop:
        PUSH    HL
        bcall(_PutC)
        POP     HL
        INC     HL
test_putString_skip:
        LD      A, (HL)
        OR      A
        JR      NZ, test_putString_loop
        POP     HL
        POP     DE
        POP     BC
        RET

;;; DATA

test_titleString:
        .db     "Test Results", 0
