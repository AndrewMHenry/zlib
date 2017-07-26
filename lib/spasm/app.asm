;;; app.asm -- File containing app boilerplate code.

;;;==========================================================================;;;
;;; USAGE ////////////////////////////////////////////////////////////////// ;;;
;;;==========================================================================;;;

;;; In order to (properly) use this library, an application must meet the
;;; following conditions:
;;;
;;;     (1) Before anything that will become part of the application code, the
;;;         application must include the present file.
;;;
;;;     (2) The application must define the symbolic equate ``APP_NAME'', which
;;;         must be an 8-character string literal (e.g. ``"Hello   "''),
;;;         somewhere that code in the present file will be able to find it.
;;;         A good place to define it would be before actually including the
;;;         present file.
;;;
;;;     (3) After including the present file, the application must include a
;;;         routine which begins with the label ``appMain''.
;;;
;;; NOTE that this file is NOT a "library" in that it has no initialization and
;;; de-initialization routines which need to be called.

;;;==========================================================================;;;
;;; BOILERPLATE //////////////////////////////////////////////////////////// ;;;
;;;==========================================================================;;;

#include "spasm_ti83plus.inc"

        .org $4000

;This is the application header definition area required for all apps.
 .db 080h,0Fh    ;Field: Program length
 .db   00h,00h,00h,00h ;Length=0 (N/A for unsigned apps)
 .db 080h,012h    ;Field: Program type
 .db   01h,04h  ;Type= Shareware, TI-83Plus
 .db 080h,021h    ;Field: App ID
 .db   01h       ;Id = 1
 .db 080h,031h    ;Field: App Build
 .db   01h       ;Build = 1
 .db 080h,048h    ;Field: App Name
 .db APP_NAME                ;Name = "Hello   " must be 8 characters
 .db 080h,081h    ;Field: App Pages
 .db 01h         ;App Pages = 1
 .db 080h,090h    ;No default splash screen
 .db 03h,026h ,09h,04h, 04h,06fh,01bh,80h     ;Field: Date stamp- 5/12/1999
 .db 02h,0dh,040h                             ;Dummy encrypted TI date stamp signature
 .db 0a1h ,06bh ,099h ,0f6h ,059h ,0bch ,067h 
 .db 0f5h ,085h ,09ch ,09h ,06ch ,0fh ,0b4h ,03h ,09bh ,0c9h 
 .db 03h ,032h ,02ch ,0e0h ,03h ,020h ,0e3h ,02ch ,0f4h ,02dh 
 .db 073h ,0b4h ,027h ,0c4h ,0a0h ,072h ,054h ,0b9h ,0eah ,07ch 
 .db 03bh ,0aah ,016h ,0f6h ,077h ,083h ,07ah ,0eeh ,01ah ,0d4h 
 .db 042h ,04ch ,06bh ,08bh ,013h ,01fh ,0bbh ,093h ,08bh ,0fch 
 .db 019h ,01ch ,03ch ,0ech ,04dh ,0e5h ,075h 
 .db 80h,7Fh      ;Field: Program Image length
 .db   0,0,0,0    ;Length=0, N/A
 .db   0,0,0,0    ;Reserved
 .db   0,0,0,0    ;Reserved
 .db   0,0,0,0    ;Reserved
 .db   0,0,0,0    ;Reserved
 
;End of header data

        CALL    appMain
        ;;
        ;; TI's code for exiting an application, with some extras.
        ;;
        IM      1
        LD      A, 01h
        CALL    000Bh
        OUT     (10h), A
        LD      A, 05h
        CALL    000Bh
        OUT     (10h), A
        bcall(_GrBufClr)
        bcall(_ClrLCDFull)
        LD      (IY+textFlags),0    ; reset text flags
        EI
        ;
        ; This next call is done only if application used the Graph Backup Buffer
        ;
        bcall(_SetTblGraphDraw)
        ;
        bcall(_ReloadAppEntryVecs)  ; make sure Application Loader set
        ;
        bcall(_JForceCmdNoChar)     ; force to home screen
