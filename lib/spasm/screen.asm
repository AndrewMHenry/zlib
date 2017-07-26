;;;==========================================================================;;;
;;; INTERFACE ////////////////////////////////////////////////////////////// ;;;
;;;==========================================================================;;;

;;; This library provides a high-level interface for the LCD.  Applications use
;;; this interface as follows:
;;;
;;;     (1) Before using any other facilities, initialize the library by calling
;;;         the ``screenInit'' routine.
;;;
;;;     (2) Whenever content is written to the screen buffer, indicate the
;;;         affected area to the library by calling an appropriate
;;;         ``screenTouch*'' routine.
;;;
;;;     (3) As required, show the screen image on the LCD by calling the
;;;         ``screenUpdate'' routine. This updates at least those areas of
;;;         the screen which have been ``touched'' since the last update
;;;         (or, for the first update, since the library was initialized).
;;;
;;; However, this library is also intended as a foundation for higher-level
;;; graphics libraries.



#define screenDataEnd           screenData
#define SCREEN_DATA_SIZE        0
        
#define screenBuffer            plotSScreen


;;; Instead of having
;;; several routines that each write to the LCD in a specialized manner, the
;;; client code will be able to 
screenInit:
        LD      A, 005h
        CALL    lcdBusy
        OUT     (010h), A
        LD      A, 001h
        CALL    lcdBusy
        OUT     (010h), A
        RET


screenExit:
        RET


screenTouchRectangle:
        RET


screenUpdate:
        PUSH    BC                     ; STACK: [PC BC]
        PUSH    DE                     ; STACK: [PC BC DE]
        PUSH    HL                     ; STACK: [PC BC DE HL]
        PUSH    IX                     ; STACK: [PC BC DE HL IX]
        LD      C, 12                  ; C = number of columns
        LD      HL, screenBuffer       ; HL = base of buffer
        CALL    screenUpdateGetLoop    ; point IX to inner loop routine
        LD      A, 080h + 0            ; set top row
        CALL    lcdBusy                ;
        OUT     (010h), A              ;
screenUpdate_Outer:                    ;
        LD      B, 64                  ; B = number of rows
        LD      DE, 12                 ; DE = offset to next row
        LD      A, 020h + 12           ; set current column
        SUB     C                      ;
        CALL    lcdBusy                ;
        OUT     (010h), A              ;
        CALL    screen_jumpIX                 ; execute inner loop
        LD      DE, -768 + 1           ; move HL to top of next column
        ADD     HL, DE                 ;
        DEC     C                      ; repeat for each column
        JR      NZ, screenUpdate_Outer ;
        POP     IX                     ; STACK: [PC BC DE HL]
        POP     HL                     ; STACK: [PC BC DE]
        POP     DE                     ; STACK: [PC BC]
        POP     BC                     ; STACK: [PC]
        RET                            ; return
        ;;
screenUpdateGetLoop:
        ;; INPUT:
        ;;   <port 002h> -- determines calculator model
        ;;   <port 020h> -- determines calculator speed if model > ti83p
        ;;
        ;; OUTPUT:
        ;;   IX -- pointer to appropriate loop routine
        ;;
        LD      IX, screenUpdateLoop6  ; assume 6 MHz loop
        IN      A, (002h)              ; return if ti83p (always 6 MHz)
        ADD     A, A                   ;
        RET     NC                     ;
        IN      A, (020h)              ; return if low speed
        OR      A                      ;
        RET     Z                      ;
        LD      IX, screenUpdateLoop15 ; use 15 MHz loop otherwise
        RET
        ;;
screenUpdateLoop6:
        ;; INPUT:
        ;;   B -- number of rows to write
        ;;   DE -- 12
        ;;   HL -- first buffer address
        ;;
        ;; OUTPUT:
        ;;   bytes written to LCD
        ;;
        ;; Not including the ``OUT'' instruction, there are 31 states
        ;; of useful work to be done per iteration.  This leaves a minimum
        ;; of 29 waste states.
        ;;
        NOP                            ; 4 states
        NOP                            ; 4 states
        LD      A, 1                   ; 7 states
        LD      A, 1                   ; 7 states
        LD      A, 1                   ; 7 states
        LD      A, (HL)                ; ACC = buffer byte
        ADD     HL, DE                 ; point HL to next row
        OUT     (011h), A              ; write buffer byte
        DJNZ    screenUpdateLoop6      ; repeat for each row
        RET                            ; return
        ;;
screenUpdateLoop15:
        ;; INPUT:
        ;;   B -- number of rows to write
        ;;   DE -- 12
        ;;   HL -- first buffer address
        ;;
        ;; OUTPUT:
        ;;   bytes written to LCD
        ;;
        ;; Exactly like screenUpdateLoop6 above, except the delay now
        ;; handles 15 MHz.  This brings the number of required wait
        ;; states up to 119.
        ;;
        PUSH    AF                     ; 11 states
        POP     AF                     ; 10 states
        PUSH    AF                     ; 11 states
        POP     AF                     ; 10 states
        PUSH    AF                     ; 11 states
        POP     AF                     ; 10 states
        PUSH    AF                     ; 11 states
        POP     AF                     ; 10 states
        PUSH    AF                     ; 11 states
        POP     AF                     ; 10 states
        LD      A, 1                   ;  7 states
        LD      A, 1                   ;  7 states
        LD      A, (HL)                ; ACC = buffer byte
        ADD     HL, DE                 ; point HL to next row
        OUT     (011h), A              ; write buffer byte
        DJNZ    screenUpdateLoop15     ; repeat for each row
        RET                            ; return        


lcdBusy:
        PUSH    AF
        CALL    000Bh
        POP     AF
        RET


screen_jumpIX:
        JP      (IX)
