;;;;;;;;;;;;;;;;;;;
;;; DEFINITIONS ;;;
;;;;;;;;;;;;;;;;;;;

#define timer                   timerData + 0
#define timerDataEnd            timerData + 2

#define TIMER_DATA_SIZE         2

timerHook:
        ;; INPUT:
        ;;   <timer data>
        ;;
        ;; OUTPUT:
        ;;   <timer data>
        ;;
        ;; The timer is decremented.
        ;;
        PUSH    HL
        LD      HL, (timer)
        DEC     HL
        LD      (timer), HL
        POP     HL
        RET

;;;;;;;;;;;;;;;;;
;;; INTERFACE ;;;
;;;;;;;;;;;;;;;;;

timerInit:
        ;; INPUT:
        ;;   <none>
        ;;
        ;; OUTPUT:
        ;;   <timer hook added>
        ;;
        ;; REQUIREMENTS:
        ;;   - Interrupts must be disabled.
        ;;   - The interrupt library must be initialized via interruptInit.
        ;;
        ;; Note that no guarantee is made regarding the initial value of the
        ;; timer.
        ;;
        PUSH    HL               ; STACK: [PC HL]
        LD      HL, timerHook    ; add timer hook
        CALL    interruptAddHook ;
        POP     HL               ; STACK: [PC]
        RET                      ; return

timerExit:
        RET


timerSet:
        ;; INPUT:
        ;;   HL -- the new value for the timer
        ;;
        ;; OUTPUT:
        ;;   <timer data> -- timer set to new value
        ;;
        LD      (timer), HL
        RET

timerGet:
        ;; INPUT:
        ;;   <timer data>
        ;;
        ;; OUTPUT:
        ;;   HL -- the current value of the timer
        ;;
        LD      HL, (timer)
        RET


timerWait:
        ;; INPUT:
        ;;   <timer data>
        ;;
        ;; OUTPUT:
        ;;   <timer data>
        ;;
        ;; This routine waits for the timer to reach 0 and then returns.
        ;;
        PUSH    HL
timerWaitLoop:
        CALL    timerGet
        LD      A, L
        OR      H
        JR      NZ, timerWaitLoop
        POP     HL
        RET
