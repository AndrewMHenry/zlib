;;; keyboard.asm

;;;==========================================================================;;;
;;; INTRODUCTION AND MOTIVATION //////////////////////////////////////////// ;;;
;;;==========================================================================;;;

;;;   About the only helpful thing the TI interrupt routine does for a game is
;;; to scan for keypresses. Unfortunately, it can also tamper with the LCD,
;;; which means routines that write directly to the screen must disable
;;; interrupts, which is undesirable for time-sensitive applications. Thus, in
;;; order to eliminate the need for TI's interrupt routine altogether, it seems
;;; good to write a simple routine to scan the keyboard for keypresses.
;;;
;;;   This file is meant to provide comprehensive support for reading keyboard
;;; input, including both key manipulation AND the keyboard-reading interrupt
;;; routine. Effectively, it is the combination of the previous contents of
;;; Keyboard.inc and KeyboardInterrupt.asm.


;;;==========================================================================;;;
;;; DEFINITIONS //////////////////////////////////////////////////////////// ;;;
;;;==========================================================================;;;

;;; variables
#define watchedKey      keyboardData + 0  ; the currently watched key:
#define watchedKeyBit   keyboardData + 0  ; - bit
#define watchedKeyGroup keyboardData + 1  ; - group
#define lastKey         keyboardData + 2  ; the last recorded key:
#define lastKeyBit      keyboardData + 2  ; - bit
#define lastKeyGroup    keyboardData + 3  ; - group
#define keyboardDataEnd keyboardData + 4  ; (END OF DATA)

#define KEYBOARD_DATA_SIZE      4

;;; constants
#define KEYBOARD_PORT   01h
#define KEYBOARD_GROUPS 7

; Interrupt routine for reading keypresses
keyboardHook:
        ;; ROUTINE keyboardIR:
        ;;
        ;;   DESCRIPTION:
        ;;     Monitor the keyboard on the Mode 2 interrupt clock,
        ;;     updating (watchedKey) and (lastKey) for use by readKey.
        ;;
        ;;   INPUTS:
        ;;     (watchedKey)  the key corresponding to the currently
        ;;                   monitored ongoing keypress.
        ;;     <keyboard>    monitored by routine
        ;;
        ;;   OUTPUTS:
        ;;     BC            (DESTROYED)
        ;;     (watchedKey)  key corresponding to newly monitored
        ;;                   ongoing keypress (if applicable)
        ;;     (lastKey)     newly finished keystroke (if applicable)
        ;;     <keyboard>    possibly reset by findKeypress or
        ;;                   keyIsPressed
        ;;
        ;;   REQUIREMENTS:
        ;;     (R1) This routine is installed as a Mode 2 interrupt
        ;;          routine (or is called by such a routine), the CPU
        ;;          is set to Interrupt Mode 2, and interrupts are
        ;;          enabled.
        ;;
        LD      BC, (watchedKey)        ; BC = watched key
        BIT     7, B                    ; if key invalid:
        JR      NZ, keyboardHook_Valid  ;
        CALL    findKeypress            ;     BC = new key
        BIT     7, B                    ;     return if still invalid  [1]
        RET     Z                       ;
        LD      (watchedKey), BC        ;     (watchedKey) = BC
        LD      (lastKey), BC           ;     (lastKey) = BC
        RET                             ;     return
keyboardHook_Valid:                     ;
        CALL  keyIsPressed              ; if BC not pressed:
        RET   Z                         ;     return
        XOR   A                         ; (watchedKey) = 0 (keypress done)
        LD    (watchedKeyGroup), A      ;
        LD    (watchedKeyBit), A        ;
        RET                             ; return
        ;; NOTES:
        ;;  [1] The most recent keypress should not be forgotten until
        ;;      another keypress occurs.  Therefore, the most recent keypress
        ;;      should not be overwritten unless a new (VALID) keypress has been
        ;;      detected.  This condition was violated by the previous version
        ;;      of this hook: once the "current" keypress ended, (watchedKey)
        ;;      and (lastKey) would both be replaced by the result of
        ;;      findKeypress REGARDLESS of whether this result was valid.  The
        ;;      hook has since been fixed to return early if the value returned
        ;;      by findKeypress is invalid.


;;;==========================================================================;;;
;;; INTERFACE ////////////////////////////////////////////////////////////// ;;;
;;;==========================================================================;;;

keyboardInit:
        ;; INPUT:
        ;;   <none>
        ;;
        ;; OUTPUT:
        ;;   <keyboard data initialized>
        ;;   <keyboard hook added>
        ;;
        PUSH    HL               ; STACK: [PC HL]
        LD      HL, 0            ; zero out (watchedKey) and (lastKey)
        LD      (watchedKey), HL ;
        LD      (lastKey), HL    ;
        LD      HL, keyboardHook ; add keyboard hook
        CALL    interruptAddHook ;
        POP     HL               ; STACK: [PC]
        RET                      ; return


keyboardExit:
        RET


keyboardRead:
        ;; ROUTINE keyboardRead:
        ;;
        ;;   DESCRIPTION:
        ;;     Retrieve most recent keystroke, clear (lastKey), and
        ;;     return the keystroke in ACC.
        ;;
        ;;   INPUTS:
        ;;     (lastKey)  most recent keystroke (DECODED;; updated by
        ;;                keyboardIR above)
        ;;
        ;;   OUTPUTS:
        ;;     ACC        most recent keystroke (ENCODED)
        ;;     (lastKey)  cleared (0)
        ;;
        ;;   REQUIREMENTS:
        ;;     (R1) The keyboardIR routine above is installed as a Mode
        ;;          2 interrupt routine (or is called by such a routine),
        ;;          the CPU is set to Interrupt Mode 2, and interrupts
        ;;          are enabled.
        ;;
        PUSH    BC              ; STACK: [PC BC]
        DI                      ; DI to avoid corrupting (lastKey)
        LD      BC, (lastKey)   ; BC = (lastKey)
        XOR     A               ; (lastKey) = 0
        LD      (lastKey+0), A  ;
        LD      (lastKey+1), A  ;
        EI                      ; EI again
        CALL    encodeKey       ; ACC = encoded (lastKey)
        POP     BC              ; STACK: [PC]
        RET                     ; return
                

keyboardWait
        ;; ROUTINE keyboardWait:
        ;;
        ;;   DESCRIPTION:
        ;;     Wait for a user keypress, then return it in ACC.
        ;;
        ;;   INPUTS:
        ;;     <keyboard>  used to detect user keypress
        ;;
        ;;   OUTPUTS:
        ;;     ACC         key pressed by user
        ;;
        CALL    keyboardRead     ; ACC = key
        OR      A                ; repeat if no key yet
        JR      Z, keyboardWait  ;
        RET                      ; return


;;;==========================================================================;;;
;;; ENCODE AND DECODE ROUTINES ///////////////////////////////////////////// ;;;
;;;==========================================================================;;;

;;;   In order to simplify this approach, we write routines for converting between
;;; the "decoded" (raw) data used by the Keyboard and the "encoded" (Key code)
;;; data seen by the programmer. As before, the encoded data will, by convention,
;;; be stored in the Accumulator. Since the decoded data spans two bytes, it will
;;; be stored in the two registers B, C (group mask in B, bit mask in C). Given
;;; a key specified by group number g and bit number b, the encoded value E, the
;;; bit value B, and the group value G corresponding to that key may be expressed
;;; as follows:
;;;
;;;     E = 8g + b + 1
;;;     G = ~(1 << g)
;;;     B = ~(1 << b)
;;;
;;; The values of g and b can both be readily solved for in terms of E by writing
;;;
;;;     b = E - 8g - 1
;;;     b % 8 = (E - 8g - 1) % 8
;;;     b = (E - 0 - 1) % 8
;;;     b = (E - 1) % 8
;;;
;;;     8g + b = E - 1
;;;     (8g + b) // 8 = (E - 1) // 8
;;;     g = (E - 1) // 8
;;;
;;; However, since solving for g and b in the expressions for B and C would
;;; involve an inverse bit shift, we will settle for an intuitive algorithmic
;;; approach. Thus, G is describable more intuitively as "all ones except a zero
;;; in bit position g," and B can be given an analogous description in terms of
;;; b. These descriptions, while perhaps less rigorous in the mathematical sense
;;; than closed-form expressions, immediately suggest appropriate conversion
;;; algorithms.

decodeKey:
        ;; ROUTINE decodeKey:
        ;;
        ;;   DESCRIPTION:
        ;;     Convert the encoded key in ACC into a group mask and bit
        ;;     mask in B and C, respectively.
        ;;
        ;;   INPUTS:
        ;;     ACC  encoded key to decode
        ;;
        ;;   OUTPUTS:
        ;;     B    group mask of decoded result
        ;;     C    bit mask of decoded result
        ;;
        ;;   REQUIREMENTS:
        ;;     (R1) ACC contains a valid key code.
        ;;
        ;; B = ~(1 << g)
        ;;   = ~(1 << (ACC - 1) // 8)
        ;; C = ~(1 << b)
        ;;   = ~(1 << (ACC - 1) % 8)
        ;;
        LD      B, ~1          ; B = ~1
        RRCA                   ; rotate bit 0 into Carry
        JR      NC, $+2+(2*1)  ; if bit 0 set:
        RLC     B              ;     rotate B left
        RRCA                   ; rotate bit 1 into Carry
        JR      NC, $+2+(2*2)  ; if bit 1 set:
        RLC     B              ;     rotate B left
        RLC     B              ;     rotate B left
        RRCA                   ; rotate bit 2 into Carry
        JR      NC, $+2+(2*4)  ; if bit 2 set:
        RLC     B              ;     rotate B left
        RLC     B              ;     rotate B left
        RLC     B              ;     rotate B left
        RLC     B              ;     rotate B left
        LD      C, ~1          ; C = ~1
        RRCA                   ; rotate bit 3 into Carry
        JR      NC, $+2+(2*1)  ; if bit 3 set:
        RLC     C              ;     rotate C left
        RRCA                   ; rotate bit 4 into Carry
        JR      NC, $+2+(2*2)  ; if bit 4 set:
        RLC     C              ;     rotate C left
        RLC     C              ;     rotate C left
        RRCA                   ; rotate bit 5 into Carry
        JR      NC, $+2+(2*4)  ; if bit 5 set:
        RLC     C              ;     rotate C left
        RLC     C              ;     rotate C left
        RLC     C              ;     rotate C left
        RLC     C              ;     rotate C left
        RET                    ; return


encodeKey:
        ;; ROUTINE encodeKey:
        ;;
        ;;   DESCRIPTION:
        ;;     Convert group mask B and bit mask C into an encoded key
        ;;     value in ACC.
        ;;
        ;;   INPUTS:
        ;;     B    group mask
        ;;     C    bit mask
        ;;
        ;;   OUTPUTS:
        ;;     ACC  encoded key
        ;;
        ;;   REQUIREMENTS:
        ;;     (R1) B and C represent the group and bit masks of a VALID
        ;;          KEY
        ;;
        ;; It is important to note that NOT EVERY PAIR (B, C) RESULTS
        ;; IN A VALID KEY! However, if the pair was found by the
        ;; findKeypress routine and the mask denotes a valid group
        ;; (the sign bit is SET) it must correspond to a valid key code.
        ;;
        ;; Also, THIS ROUTINE WILL HANG if either B or C has no bits
        ;; reset! Again, this will not be an issue if B and C are valid
        ;; output from findKeypress.
        ;;
        XOR     A       ; assume ACC = 0
        BIT     7, B    ; return if invalid key
        RET     Z       ;
        PUSH    BC      ; STACK: [PC BC]
        DEC     A       ; ACC = -1
        INC     A       ; ++ A
        RRC     B       ; rotate B right
        JR      C, $-3  ; repeat from `INC A' if no reset bit yet
        ADD     A, A    ; ACC *= 2  (2x)
        ADD     A, A    ; ACC *= 2  (4x)
        ADD     A, A    ; ACC *= 2  (8x)
        INC     A       ; ++ A
        RRC     C       ; rotate C right
        JR      C, $-3  ; repeat from `INC A' if no reset bit yet
        POP     BC      ; STACK: [PC]
        RET             ; return




;;;==========================================================================;;;
;;; KEYBOARD PORT INTERFACE ROUTINES /////////////////////////////////////// ;;;
;;;==========================================================================;;;

keyIsPressed:
        ;; ROUTINE keyIsPressed:
        ;;
        ;;   DESCRIPTION:
        ;;     Set [Zero] if and only if the key represented by the
        ;;     group mask in B and the bit mask in C is currently being
        ;;     pressed according to the keyboard port.
        ;;
        ;;   INPUTS:
        ;;     B           the group mask of the key to check
        ;;     C           the bit mask of the key to check
        ;;     <keyboard>  determines whether key is pressed
        ;;
        ;;   OUTPUTS:
        ;;     [Zero]      set iff key pressed
        ;;     <keyboard>  reset at beginning by writing FFh
        ;;
        ;;   REQUIREMENTS:
        ;;     (R1) B and C represent the group and bit mask of a valid
        ;;          key.
        ;;
        ;; THIS ROUTINE ASSUMES THAT THE MASK IN C HAS ONLY ONE BIT
        ;; RESET!!! Under this assumption, C specifies only one key,
        ;; and that key is being pressed if and only if its reset bit
        ;; is ALSO reset in the input from the Keyboard Port. That is,
        ;; for every bit position 0 <= b < 8, the mask bit C[b] and the
        ;; input bit O[b] must satisfy
        ;;
        ;;     ~(~C[b] AND O[b])
        ;;     ~~C[b] OR ~O[b]
        ;;     C[b] OR ~O[b]
        ;;
        ;; That is,
        ;;
        ;;     C[b] OR ~O[b] == 1
        ;;
        ;; for every bit position b. Thus, considering the entire bytes
        ;; C and O, our condition (for SUCCESS) is equivalent to
        ;;
        ;;     C OR ~O == FFh
        ;;     C OR ~O + 1 == FFh + 1 == 0
        ;;
        ;; Since we want to set the Zero flag if and only if we DO have
        ;; success, the appropriate flag result will be achieved by
        ;; simply evaluating the expression on the left-hand side of
        ;; this equation.
        ;;
        LD      A, 0FFh             ; reset keyboard by writing FFh
        OUT     (KEYBOARD_PORT), A  ;
        LD      A, B                ; ACC = group mask
        OUT     (KEYBOARD_PORT), A  ; write group mask to keyboard
        IN      A, (KEYBOARD_PORT)  ; ACC = byte O from keyboard
        CPL                         ; ACC = ~O
        OR      C                   ; ACC = ~O OR C
        INC     A                   ; ACC = ~O OR C + 1
        RET                         ; return


findKeypress:
        ;; ROUTINE findKeypress:
        ;;
        ;;   DESCRIPTION:
        ;;     Return the "best" key currently being pressed.
        ;;
        ;;   INPUTS:
        ;;     <keyboard>  read to find keypress
        ;;
        ;;   OUTPUTS:
        ;;     B           group mask of key
        ;;     C           bit mask of key
        ;;     <keyboard>  reset by writing FFh
        ;;
        ;; The output represents a valid key if and only if the sign
        ;; bit (bit 7) of B is SET.
        ;;
        LD      B, 11111110b           ; B = 11111110b (first group mask)
findKeypress_Loop:                     ;
        LD      A, 0FFh                ; reset keyboard by writing FFh
        OUT     (KEYBOARD_PORT), A     ;
        LD      A, B                   ; write B to keyboard
        OUT     (KEYBOARD_PORT), A     ;
        IN      A, (KEYBOARD_PORT)     ; ACC = byte R from keyboard
        INC     A                      ; ACC = R + 1
        JR      NZ, findKeypress_Break ; break if R + 1 NONZERO  [1]
        RLC     B                      ; rotate mask LEFT
        JP      M, findKeypress_Loop   ; repeat if 0 bit still in range
        RET                            ; return because key not found
findKeypress_Break:                    ;
        DEC     A                      ; ACC = R again
        LD      C, A                   ; C = R
        RET                            ; return
        ;;
        ;; [1] In terms of the INITIAL READ VALUE R, the break condition
        ;;     may be written
        ;;
        ;;       R + 1 nonzero.
        ;;       <==> R + 1 != 0
        ;;       <==> NOT (R + 1 == 0)
        ;;       <==> NOT (R + 1 == FFh + 1)
        ;;       <==> NOT (R == FFh)
        ;;       <==> NOT "All bits of R are set."
        ;;       <==> NOT "No bits of R are reset."
        ;;       <==> NOT NOT "At least one bit of R is reset."
        ;;       <==> "At least one bit of R is reset."
