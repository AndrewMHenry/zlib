;;;==========================================================================;;;
;;; BUGS /////////////////////////////////////////////////////////////////// ;;;
;;;==========================================================================;;;
;;; #       STATUS      DESCRIPTION                                          ;;;
;;; ------------------------------------------------------------------------ ;;;
;;; 1       [FIXED]     failure to initialize (interruptHookDispatch) and    ;;;
;;;                     (interruptHookCount)                                 ;;;
;;;==========================================================================;;;

;;;;;;;;;;;;;;;;;;;;;
;;; VARIABLE DATA ;;;
;;;;;;;;;;;;;;;;;;;;;

#define INTERRUPT_MAX_HOOKS     3

#define interruptHookCount      interruptData + 0
#define interruptHookDispatch   interruptData + 1
#define interruptDataEnd        interruptData + (3*INTERRUPT_MAX_HOOKS) + 1

#define INTERRUPT_DATA_SIZE     (3*INTERRUPT_MAX_HOOKS) + 1


;;;;;;;;;;;;;;;;;;;
;;; DEFINITIONS ;;;
;;;;;;;;;;;;;;;;;;;

#define INTERRUPT_WRAPPER_SIZE  interruptWrapperEnd - interruptWrapper


#define INTERRUPT_MASK          00001011b

#define INTERRUPT_TABLE_MSB     8Bh
#define INTERRUPT_TABLE         INTERRUPT_TABLE_MSB * 0100h
#define INTERRUPT_TABLE_SIZE    256 + 1

#define INTERRUPT_CODE_MSB      8Ah
#define INTERRUPT_CODE          INTERRUPT_CODE_MSB * 0101h


interruptWrapper:
        EX      AF, AF'                ;
        EXX                            ;
        IN      A, (04h)               ; read interrupt sources
        CPL                            ; flip bits to RESET sources
        AND     INTERRUPT_MASK         ; ignore irrelevant bits
        OUT     (03h), A               ; acknowledge relevant sources
        LD      A, INTERRUPT_MASK      ; ACC = 1 for each interrupt source
        OUT     (03h), A               ; re-enable each interrupt source
        CALL    interruptHookDispatch  ; call installed interrupt handlers
        EXX                            ;
        EX      AF, AF'                ;
        EI                             ;
        RETI                           ;
interruptWrapperEnd:



;;;;;;;;;;;;;;;;;
;;; INTERFACE ;;;
;;;;;;;;;;;;;;;;;

;;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;; USAGE EXAMPLE:
;;;
;;;     startApp:
;;;             CALL    interruptInit     ; initialize library
;;;             LD      HL, timerHook     ; install timer hook
;;;             CALL    interruptAddHook  ;
;;;             LD      HL, keyboardHook  ; install keyboard hook
;;;             CALL    interruptAddHook  ;
;;;             EI                        ; interrupts are now ready
;;;             ;
;;;             ; <main application code>
;;;             ;
;;;             JP      exitApp           ; restore interrupt mode, etc.
;;;
;;; If a library requires an interrupt hook to run, it is a good idea to
;;; install the hook in a library initialization routine.  In this case,
;;; it is important that interruptInit is called before the initialization
;;; routine of the higher-level library.
;;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

interruptInit:
        ;; INPUT:
        ;;   <none>
        ;;
        ;; OUTPUT:
        ;;   <interrupt data initialized>
        ;;   <interrupts DISABLED>
        ;;
        ;; This routine installs the interrupt handler wrapper and
        ;; prepares it for the installation of additional hooks.
        ;;
	PUSH    BC                            ; STACK: [PC BC]
	PUSH    DE                            ; STACK: [PC BC DE]
	PUSH    HL                            ; STACK: [PC BC DE HL]
	DI                                    ; INTERRUPTS OFF
	LD      A, INTERRUPT_MASK             ; enable our interrupts
	OUT     (03h), A                      ;
        LD      BC, INTERRUPT_WRAPPER_SIZE    ;
	LD      DE, INTERRUPT_CODE            ; load interrupt code
        LD      HL, interruptWrapper          ;
	LDIR                                  ;
	LD      HL, INTERRUPT_TABLE           ; load IR table
	LD      (HL), INTERRUPT_CODE_MSB      ;
	LD      DE, INTERRUPT_TABLE + 1       ;
	LD      BC, INTERRUPT_TABLE_SIZE - 1  ;
	LDIR                                  ;
        XOR     A                             ; (interruptHookCount) = 0
        LD      (interruptHookCount), A       ;
        LD      A, 0C9h                       ; first dispatch instruction = RET
        LD      (interruptHookDispatch), A    ;
	LD      A, INTERRUPT_TABLE_MSB        ; I register = MSB of table
	LD      I, A                          ;
	IM      2                             ; set interrupts to mode 2
	POP     HL                            ; STACK: [PC BC DE]
	POP     DE                            ; STACK: [PC BC]
	POP     BC                            ; STACK: [PC]
	RET                                   ; return


interruptExit:
        RET


interruptAddHook:
        ;; INPUT:
        ;;   HL -- address of hook routine to add
        ;;
        ;; OUTPUT:
        ;;   <interrupt data> -- hook added to interrupt handler
        ;;
        ;; REQUIREMENTS:
        ;;   - Interrupts must be disabled when calling this routine.
        ;;   - The hook routine must preserve all registers.
        ;;   - The correctness of the hook routine must not depend on the
        ;;     order in which the installed hooks are executed.
        ;;
        PUSH    BC                         ; STACK: [PC BC] 
        PUSH    DE                         ; STACK: [PC BC DE]
        PUSH    HL                         ; STACK: [PC BC DE HL]
        EX      DE, HL                     ; DE = routine address
        LD      A, (interruptHookCount)    ; ACC = count
        LD      L, A                       ; HL = count * 3 + dispatch base
        LD      H, 0                       ;
        LD      C, L                       ;
        LD      B, H                       ;
        ADD     HL, HL                     ;
        ADD     HL, BC                     ;
        LD      BC, interruptHookDispatch  ;
        ADD     HL, BC                     ;
        LD      (HL), 0CDh                 ; write CALL to routine
        INC     HL                         ;
        LD      (HL), E                    ;
        INC     HL                         ;
        LD      (HL), D                    ;
        INC     HL                         ;
        LD      (HL), 0C9h                 ; write RET instruction
        INC     A                          ; count = original count + 1
        LD      (interruptHookCount), A    ;
        POP     HL                         ; STACK: [PC BC DE]
        POP     DE                         ; STACK: [PC BC]
        POP     BC                         ; STACK: [PC]
        RET                                ; return
