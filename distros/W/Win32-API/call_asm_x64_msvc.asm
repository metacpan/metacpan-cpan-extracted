.CODE

; void Call_x64_real(FARPROC ApiFunction, size_t *int_registers, double *float_registers, stackitem *stack, unsigned int nstack)
Call_x64_real PROC FRAME


    ; store register parameters
    mov qword ptr[rsp+32], r9  ; stack
    mov qword ptr[rsp+24], r8  ; float_registers
    mov qword ptr[rsp+16], rdx ; int_registers
    mov qword ptr[rsp+8],  rcx ; ApiFunction

;old code, I couldn't get SAVEREG to work, maybe someone else can
;so instead the push was added, and all the ebp offsets +8'ed
;    mov qword ptr[rsp-16], rbp
    push rbp
    .PUSHREG rbp
    mov rbp, rsp
    
    .SETFRAME rbp, 0
    .ENDPROLOG

    ; Now floating-point registers
    mov rax, qword ptr [rbp+32]
    movsd xmm0, qword ptr [rax]
    movsd xmm1, qword ptr [rax+8]
    movsd xmm2, qword ptr [rax+16]
    movsd xmm3, qword ptr [rax+24]

    ; Now the stack
    mov r11, qword ptr [rbp+40]
    mov eax, dword ptr [rbp+48]

    ;align stack so *after* the copystack loop it will be 16 bytes
    ;do 32 bits, GBs of stack params is impossible
    mov r10d, eax
    ;if odd set al to 1
    and eax, 1H
    ;boost 1 to 8 if its 1, if its 0 it will remain 0
    shl eax, 3
    ;rax might be zero or not, all eax ops zero extend upper 32 bits
    sub rsp, rax
    mov eax, r10d

    ; Except not if there isn't any
    test eax, eax
    jz docall

copystack:
    sub eax, 1
    ;upper bits of rax are zero
    mov r10, qword ptr [r11+8*rax]
    push r10
    test eax, eax
    jnz copystack

docall:
    ; Load up integer registers first...
    mov rax, qword ptr [rbp+24]

    mov rcx, qword ptr [rax]
    mov rdx, qword ptr [rax+8]
    mov r8,  qword ptr [rax+16]
    mov r9,  qword ptr [rax+24]
    sub rsp, 32 ;Microsoft x64 calling convention - allocate 32 bytes of "shadow space" on the stack
    ; And call
    mov r10, qword ptr [rbp+16]
    call r10

    ;pass through rax and xmm0 to caller
    ; Cleanup
    mov rsp, rbp
;old code, see note above
;    mov rbp, qword ptr [rsp-16]    
    pop rbp

    ret

Call_x64_real ENDP

END
