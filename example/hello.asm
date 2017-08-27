#define APP_NAME "Hello   "
#include "app.asm"

; library inclusions
;
#include "screen.asm"     ; screenUpdate,               [dependency]
#include "draw.asm"       ; drawClearScreen             [dependency]
#include "write.asm"      ; writeSetFont, writeString
#include "interrupt.asm"  ;                             [dependency]
#include "keyboard.asm"   ; keyboardWait

; memory equates
;
#define screenData      saveSScreen
#define drawData        saveSScreen+SCREEN_DATA_SIZE
#define writeData       saveSScreen+SCREEN_DATA_SIZE+DRAW_DATA_SIZE
#define interruptData   saveSScreen+SCREEN_DATA_SIZE+DRAW_DATA_SIZE+WRITE_DATA_SIZE
#define keyboardData    saveSScreen+SCREEN_DATA_SIZE+DRAW_DATA_SIZE+WRITE_DATA_SIZE+INTERRUPT_DATA_SIZE

; resource inclusion
;
; This file contains the definition of the font (fontFBF) we use to write
; the greeting.
;
#include "fontFBF.asm"

appMain:
        CALL    screenInit       ; initialize libraries, lowest to highest
        CALL    drawInit         ;
        CALL    writeInit        ;
        CALL    interruptInit    ;
        CALL    keyboardInit     ;
        LD      HL, fontFBF      ; set font to fontFBF
        CALL    writeSetFont     ;
        CALL    drawClearScreen  ; clear previous contents of screen buffer
        LD      DE, 0            ; D, E = top of screen, left of screen
        LD      HL, helloString  ; HL = greeting string
        CALL    writeString      ; write string at top left of screen buffer
        CALL    screenUpdate     ; flush string to LCD
        CALL    keyboardWait     ; wait for user keypress
        CALL    keyboardExit     ; de-initialize libraries, highest to lowest
        CALL    interruptExit    ;
        CALL    writeExit        ;
        CALL    drawExit         ;
        CALL    screenExit       ;
        RET                      ; return

helloString:
        .db     "HELLO WORLD!", 0
