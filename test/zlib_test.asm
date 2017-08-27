main:
        PUSH    HL
        LD      HL, zlibTests
        CALL    testLoad
        CALL    testMain
        POP     HL
        RET

zlibTests:
        .dw     0
