main:
        PUSH    HL
        LD      HL, zlibTests
        CALL    testLoad
        CALL    testMain
        POP     HL
        RET

zlibTestFail:
        LD      A, TEST_RESULT_FAILED
        RET

zlibTestPass:
        LD      A, TEST_RESULT_PASSED
        RET

zlibTests:
        .dw     zlibTestFail
        .dw     zlibTestPass
        .dw     0
