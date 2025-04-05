global print

;================================================================================|
;================================================================================|
;                                      MACRO                                     |
;================================================================================|
;================================================================================|

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
    ; call printSignedInteger
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
    push rcx
    push r11

    mov rax, 1          ; "write" syscall index
    mov rdi, 1          ; stdout
    mov rsi, BUFFER     ;
    mov rdx, r8         ; strlen
    syscall             ; remember that it brokes rcx and r11

    pop r11
    pop rcx
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
; Flush numbers buffer when it about to overflow
; Input:  none
; Output: none
;==============================================================|
%macro CleanNumbersBuffer 0
    push rsi

    mov rsi, qword [NUMBER_BUFFER_LEN]
    dec rsi

%%while:
    mov byte [NUMBER_BUFFER + rsi], 0
    dec rsi
    cmp rsi, 0
    jge %%while

    pop rsi
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

    cmp r8, qword [BUFFER_LEN]
    jne %%exit

    flushBuffer         ; if buffer about to overflow -> flush it

%%exit:
%endmacro

; =============================================================|
; Get Digit and numerical system base (Anti-copypaste macros)
; Input:  none
; Output: cl - base, ch - mask
;==============================================================|
%macro getDigitAndNumeralSystem 2
    push rcx
    xor rcx, rcx

    push rax

    movsx rax, dword [rbp + r10]
    add r10, 8

    mov cl, %1
    mov ch, %2

%%exit:
%endmacro

;================================================================================|
;================================================================================|
;                                   FUNCTIONS                                    |
;================================================================================|
;================================================================================|

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
    ;===================;
    ;        %RBP       ;
    ;===================; <---------- %RBP
    ;        arg5       ;
    ;===================;
    ;        arg4       ;
    ;===================;
    ;        arg3       ;  Stack Frame
    ;===================;    Picture
    ;        arg2       ;
    ;===================;
    ;        arg1       ;
    ;===================; <---------- %RBP + %R10
    ;        arg0       ;
    ;===================; <---------- %RSP

    pop rsi             ; rsi = &(format string)
    mov rdi, BUFFER     ; rdi = &(BUFFER)
    mov r10, -40        ; r10 = argument shift

    call myPrint        ; After pushs I work by "cdecl calling convention"

    add rsp, 40         ; clean Stack Frame
    pop rbp             ; reset rbp

.exit:
    mov eax, eax
    ret

;==============================================================|
; Char printing function
; Input:  %rsi = &(format string)
;         %rdi = &(BUFFER)
;         %bl  = character
; Output: %eax = number of printed characters eax
;==============================================================|
myPrint:
    push r8
    xor r8, r8
    xor rax, rax

.printNextCharacter:
    cmp byte [rsi], 0   ; Check if symbol isn't end of line
    je .exit

    ; cmp r10, 0
    ; jne .continue

    ; mov r10, 16

; .continue:
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
;%b============================================================|
printBinary:
    getDigitAndNumeralSystem 1, 1

    call printBinOctHexNumeralSystem

    pop rcx             ; rcx = rax ~ number of already printed characters
    add rax, rcx        ; eax = number of printed characters + printed digits

    pop rcx             ; reset rcx value

    prepareForTheNextCharacter
    dec rax

    ret

;%c============================================================|
printSingleCharacter:
    mov bl, byte [rbp + r10]
    add r10, 8

    putCharInBuffer
    prepareForTheNextCharacter

    ret

;%d============================================================|
printSignedInteger:
    getDigitAndNumeralSystem 10, 10

    mov rcx, 10
    push rdx
    xor rdx, rdx
    call printDecimalNumeralSystem

    pop rdx
    pop rcx             ; rcx = rax ~ number of already printed characters
    add rax, rcx        ; eax = number of printed characters + printed digits
    pop rcx             ; reset rcx value

    prepareForTheNextCharacter
    dec rax

    ret

;%o============================================================|
printUnsignedOctal:
    getDigitAndNumeralSystem 3, 7

    call printBinOctHexNumeralSystem

    pop rcx             ; rcx = rax ~ number of already printed characters
    add rax, rcx        ; eax = number of printed characters + printed digits

    pop rcx             ; reset rcx value

    prepareForTheNextCharacter
    dec rax

    ret

;%s============================================================|
printCharacterString:
    push r14
    mov r14, qword [rbp + r10]
    add r10, 8

    push r13
    xor r13, r13
    push rbx

.while:
    mov bl, [r14 + r13]
    putCharInBuffer
    prepareForTheNextCharacter
    dec rsi

    inc r13

    cmp bl, 0
    jg .while

.exit:
    pop rbx
    pop r13
    pop r14

    prepareForTheNextCharacter
    dec rax

    ret

;%u============================================================|
printUnsignedDecimal:
    getDigitAndNumeralSystem 10, 10

    mov rcx, 10
    push rdx
    xor rdx, rdx
    call printDecimalNumeralSystem

    pop rdx
    pop rcx             ; rcx = rax ~ number of already printed characters
    add rax, rcx        ; eax = number of printed characters + printed digits
    pop rcx             ; reset rcx value

    prepareForTheNextCharacter
    dec rax

    ret

;%h============================================================|
printUnsignedHex:
    getDigitAndNumeralSystem 4, 15

    call printBinOctHexNumeralSystem

    pop rcx             ; rcx = rax ~ number of already printed characters
    add rax, rcx        ; eax = number of printed characters + printed digits

    pop rcx             ; reset rcx value

    prepareForTheNextCharacter
    dec rax

    ret

;%%============================================================|
printPercent:
    mov bl, '%'
    putCharInBuffer
    prepareForTheNextCharacter

    ret

;%?============================================================|
undefinedFormatSpecifier:
    mov bl, '%'
    putCharInBuffer
    prepareForTheNextCharacter
    dec rsi

    mov bl, byte [rsi]
    putCharInBuffer

    ret

;==============================================================|
; Print Bin/Oct/Hex numeral system digits
; Input:  rax - Digit
;         ch - 1/7/15 (mask)
;         cl - 1/3/4  (base of numerical system = 2^cl)
;         rbx - broken
; Output: rax - Number of printed digits
;==============================================================|
printBinOctHexNumeralSystem:
    push rbx
    xor rbx, rbx

    push r13
    xor r13, r13

.loop:
	mov bl, al
	and bl, ch          ; Get only one digit with mask
	add bl, 48	        ; add ascii code of "0"

	cmp bl, 57          ; check if it's letter symbol (10-16)
	jle .insert_byte
	add bl, 39	        ; add ascii code of "a"

.insert_byte:
	mov [NUMBER_BUFFER + r13], bl
	inc r13

	shr eax, cl	        ; shift to the next digit

	test eax, eax	    ; loop requirement
	jnz .loop

    push r13
    dec r13

.printToBuffer:
    mov bl, byte [NUMBER_BUFFER + r13]
    dec r13
    mov byte [rdi + r8], bl
    prepareForTheNextCharacter
    dec rsi

    cmp r13, 0
    jge .printToBuffer

.exit:
    dec r8
    pop rax             ; rax = r13 ~ number of printed digits

    pop r13
    pop rbx

    ret

;==============================================================|
; Print Decimal numeral system digits
; Input:  rax - Digit
;         rbx - broken (fixed)
;         rdx - broken (fixed)
;         cl  = 10
; Output: rax - Number of printed digits
;==============================================================|
printDecimalNumeralSystem:
    push rbx
    xor rbx, rbx

    push r13
    xor r13, r13

    push rax
    cmp rax, 0
    jge .positiveInteger

    neg rax
    mov bl, '-'
    putCharInBuffer
    prepareForTheNextCharacter
    dec rsi
    dec rax

.positiveInteger:
    mov rbx, rax
    div rcx

.loop:
	add dl, 48	        ; add ascii code of "0"

.insert_byte:
	mov [NUMBER_BUFFER + r13], dl
	inc r13

    xor rdx, rdx

    mov rbx, rax
	div rcx             ; shift to the next digit

	test edx, edx	    ; loop requirement
	jnz .loop
    test eax, eax
	jnz .loop

    push r13
    dec r13

.printToBuffer:
    mov bl, byte [NUMBER_BUFFER + r13]
    dec r13
    mov byte [rdi + r8], bl
    prepareForTheNextCharacter
    dec rsi

    cmp r13, 0
    jge .printToBuffer

.exit:
    dec r8

    pop rax             ; rax = r13 ~ number of printed digits
    pop r13             ; r13 = rax (input digit)
    cmp r13, 0
    jge .dontPrintMinus
    add rax, 1

.dontPrintMinus:
    pop r13
    pop rbx

    ret

;================================================================================|
;================================================================================|
;                                      DATA                                      |
;================================================================================|
;================================================================================|
section .data
BUFFER_LEN:         dq 8
NUMBER_BUFFER_LEN:  dq 32
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

;==============================================================|
; BSS SECTION
;==============================================================|
section .bss
NUMBER_BUFFER:      resb 32
BUFFER:             resb 8