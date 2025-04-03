global print

;==============================================================|
; TEXT SECTION
;==============================================================|
section .text
; =============================================================|
; Jumps to the handler function, depending on the specifier
; Input:  bl = format specifier
; Output: stdout
;==============================================================|
%macro chooseFormatSpecifierHandler 0

    cmp bl, 'x'         ; if bl > 'x' ---> percentSpecifier or undefined
    jg %%percentSpecifier

    cmp bl, 'a'         ; if bl < 'a' ---> percentSpecifier or undefined
    jl %%percentSpecifier

    sub bl, 'a'         ; (bl - a) * 8 = shift for functions_table
    shl bl, 3
    mov bl, bl

    call [FUNCTIONS_TABLE + rbx]
    jmp %%exit

%%percentSpecifier:
    cmp bl, '%'
    jne %%undefined

    call printPercent
    jmp %%exit

%%undefined:
    call undefinedFormatSpecifier

%%exit:

%endmacro

; =============================================================|
; Print BUFFER to stdout when it about to overflow
; Input:  BUFFER, r8
; Output: stdout
;==============================================================|
%macro printBuffer 0

    push rsi            ; Save registers values
    push rdx            ;
    push rdi            ;
    push rax            ;

    mov rax, 1          ; "write" syscall index
    mov rdi, 1          ; stdout
    mov rsi, BUFFER     ;
    mov rdx, r8         ; strlen
    syscall             ; remember that it brokes rcx and r11

    pop rax
    pop rdi
    pop rdx
    pop rsi

%endmacro

; =============================================================|
; Put character in BUFFER
; Input:  bl  = ascii code of writing char,
;         rbi = &(BUFFER),
;         r8  = shift
; Output: none
;==============================================================|
%macro putCharInBuffer 0

    mov [rdi + r8], bl

%endmacro

; =============================================================|
; Flush buffer when it about to overflow
; Input:  r8  = shift
; Output: none
;==============================================================|
%macro flushBuffer 0

    printBuffer
    xor r8, r8

%endmacro

; =============================================================|
; Increase all counters and buffer overflow check
; Input:  none
; Output: none
;==============================================================|
%macro prepareForTheNextCharacter 0

    inc r8              ; BUFFER shift
    inc rsi             ; Format string counter
    inc eax             ; Function return value counter

    cmp r8, [BUFFER_LEN]
    jne %%exit

    flushBuffer         ; if buffer about to overflow -> flush it

%%exit:

%endmacro

;==============================================================|
; MyPrint wrap - handles input arguments
; Input:  %rbp - array of arguments
; Output: %eax - number of printed characters
;==============================================================|
print:
    push rbp            ; save %rbp
    mov rbp, rsp

    push r9             ; Linux ABI parameters passing requirement
    push r8
    push rcx
    push rdx
    push rsi
    push rdi

    ;===================;
    ;        ...        ;
    ;===================;
    ;        arg6       ;
    ;===================;
    ;    return code    ;
    ;===================; <---------- %RBP
    ;        %RBP       ;
    ;===================;
    ;        arg5       ;
    ;===================;
    ;        arg4       ;
    ;===================;
    ;        arg3       ;  Stack Frame
    ;===================;    Picture
    ;        arg2       ;
    ;===================;
    ;        arg1       ;
    ;===================;
    ;        arg0       ;
    ;===================; <---------- %RSP

    pop rsi             ; rsi = &(format string)
    mov rdi, BUFFER     ; rdi = &(BUFFER)

    call myPrint        ; After pushs I work by "cdecl calling convention"

    add rsp, 40         ; clear Stack Frame
    pop rbp             ; reset rbp

.exit:
    mov eax, eax
    ret

;==============================================================|
; Char printing function
; Input:  %rsi = &(format string)
;         %rdi = &(BUFFER)
; Output: %eax = number of printed characters eax
;==============================================================|
myPrint:
    push r8
    xor r8, r8
    xor rax, rax

.printNextCharacter:
    cmp byte [rsi], 0   ; Check if symbol isn't end of line
    je .exit

    mov bl, byte [rsi]  ; bl = character to print || specifier
    cmp bl, '%'
    je .processFormatSpecifier

    putCharInBuffer     ; put character in BUFFER macros

    prepareForTheNextCharacter

    jmp .printNextCharacter

.processFormatSpecifier:
    inc rsi
    mov bl, byte [rsi]  ; bl = specifier
    cmp bl, 0           ; Check if symbol isn't end of line
    je .exit

    chooseFormatSpecifierHandler

    prepareForTheNextCharacter

    jmp .printNextCharacter

.exit:
    printBuffer
    pop r8

    ret

;==============================================================|
; Format Specifier Handlers
; Input:  none
; Output: none
;==============================================================|

printBinary:
    mov bl, 'B'

    putCharInBuffer
    ret

printSingleCharacter:
    mov bl, 'C'
    putCharInBuffer
    ret

printSignedInteger:
    mov bl, 'D'
    putCharInBuffer
    ret

printUnsignedOctal:
    mov bl, 'O'
    putCharInBuffer
    ret

printCharacterString:
    mov bl, 'S'
    putCharInBuffer
    ret

printUnsignedDecimal:
    mov bl, 'U'
    putCharInBuffer
    ret

printUnsignedHex:
    mov bl, 'X'
    putCharInBuffer
    ret

printPercent:
    mov bl, '%'
    putCharInBuffer
    ret

undefinedFormatSpecifier:
    mov bl, '-'
    putCharInBuffer
    ret

;==============================================================|
; DATA SECTION
;==============================================================|
section .data
BUFFER_LEN:         dw 8
ARGUMENTS_SHIFT:    db 0
FUNCTIONS_TABLE:
    dq undefinedFormatSpecifier         ;%a

    dq printBinary                      ;%b
    dq printSingleCharacter             ;%c
    dq printSignedInteger               ;%d

    dq undefinedFormatSpecifier         ;%e
    dq undefinedFormatSpecifier         ;%f
    dq undefinedFormatSpecifier         ;%g
    dq undefinedFormatSpecifier         ;%h
    dq undefinedFormatSpecifier         ;%i
    dq undefinedFormatSpecifier         ;%j
    dq undefinedFormatSpecifier         ;%k
    dq undefinedFormatSpecifier         ;%l
    dq undefinedFormatSpecifier         ;%m
    dq undefinedFormatSpecifier         ;%n

    dq printUnsignedOctal               ;%o

    dq undefinedFormatSpecifier         ;%p
    dq undefinedFormatSpecifier         ;%q
    dq undefinedFormatSpecifier         ;%r

    dq printCharacterString             ;%s

    dq undefinedFormatSpecifier         ;%t

    dq printUnsignedDecimal             ;%u

    dq undefinedFormatSpecifier         ;%v
    dq undefinedFormatSpecifier         ;%w

    dq printUnsignedHex                 ;%x

    ;dq printPercent                     ;%% - обрабатывать отдельно, как и заглавные спецификаторы
    ;dq undefinedFormatSpecifier         ;%? - should print "%?"

;==============================================================|
; BSS SECTION
;==============================================================|
section .bss
BUFFER:             resb 256

; TODO color