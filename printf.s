global print

section .text
; ==============================================================|
; Macros to print buffer to stdout when it about to overflow
; Input:  none
; Output: stdout
;==============================================================|
%macro printBuffer 0

    push rsi              ; Save registers values
    push rdx              ;
    push rdi              ;
    push rax              ;

    mov rax, 1            ; "write" syscall index
    mov rdi, 1            ; stdout
    mov rsi, buffer       ;
    mov rdx, r8           ; strlen
    syscall               ; remember that it brokes rcx and r11

    pop rax
    pop rdi
    pop rdx
    pop rsi

%endmacro

; ==============================================================|
; Macros to put character in buffer
; Input:  bl  - ascii code of writing char,
;         rbi = &(buffer) + shift
; Output: none
;==============================================================|
%macro putCharInBuffer 0

    mov [rdi + r8], bl

%endmacro

;==============================================================|
; String printing function
; Input:  %rbp - array of arguments
; Output: %eax - number of printed characters
;==============================================================|
print:
    push rbp            ; save %rbp
    mov rbp, rsp

    push r9             ; Linux ABI parameters passing requirement
    push r8             ;
    push rcx            ;
    push rdx            ;
    push rsi            ;
    push rdi            ;

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
    mov rdi, buffer     ; rdi = &(buffer)

    call myPrint        ; After pushs I work by "cdecl calling convention"

    add rsp, 40         ; clear Stack Frame

    pop rbp             ; reset rbp

.exit:
    ret

;==============================================================|
; Char printing function
; Input:  cdecl calling convention
; Output: %eax - number of printed characters eax
;==============================================================|
myPrint:
    push r8
    xor r8, r8

.printNextCharacter:
    cmp byte [rsi], 0   ; Check if symbol isn't end of line
    je .exit

    mov bl, byte [rsi]  ; bl = character to print
    putCharInBuffer     ; put character in buffer macros

    inc r8              ; Buffer shift
    inc rsi             ; Format string counter
    inc eax             ; Function return value counter

    cmp r8, [buffer_len]
    je .flushBuffer

    jmp .printNextCharacter

.flushBuffer:
    printBuffer
    xor r8, r8
    jmp .printNextCharacter

.exit:
    printBuffer

    pop r8

    ret

section .data
buffer_len: dw 8

section .bss
buffer:     resb 256