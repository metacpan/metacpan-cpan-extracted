.386P
.model FLAT
PUBLIC	@Call_asm@16
EXTRN   __imp__IsDebuggerPresent@0:NEAR
IFDEF PERL_IMPLICIT_CONTEXT
EXTRN   __imp__Perl_croak_nocontext:NEAR
ELSE
EXTRN   __imp__Perl_croak:NEAR
ENDIF
EXTRN   _bad_esp_msg:NEAR
; Function compile flags: /Ogsy
;	COMDAT @Call_asm@16
_TEXT	SEGMENT
_control$ = 8						; size = 4
_retval$ = 12						; size = 4
T_DOUBLE = 11
T_FLOAT = 10
@Call_asm@16 PROC NEAR					; COMDAT
param equ ecx
params_start equ edx
retval  equ edi

; 51   : {
	push	ebp
	mov	ebp, esp
	push	esi
	push    edi

; 128  : #if (defined(_MSC_VER) || defined(BORLANDC))
; 129  : 			__asm {
	mov	esi, DWORD PTR _control$[ebp]
	jmp	SHORT gt_param_test
loop_body:

; 72   :         param--;

	sub	param, 16					; 00000010H

; 73   :         p.qParam = param->q;

	mov	al, BYTE PTR [param+8]

; 74   : 		switch(param->t) {

	cmp	al, T_DOUBLE-1 ;T_DOUBLE and higher are 64 bit types
        ; -1 bc in params are --ed to remove T_VOID hole
	jb	SHORT push_low_dword
push_high_dword:
	push	DWORD PTR [param+4]
push_low_dword:
	push	DWORD PTR [param]

; 128  : #if (defined(_MSC_VER) || defined(BORLANDC))
; 129  : 			__asm {

gt_param_test:

; 52   : 
; 53   :     /* int    iParam; */
; 54   :     union{
; 55   :     long   lParam;
; 56   :     float  fParam;
; 57   :     double dParam;
; 58   :     /* char   cParam; */
; 59   :     char  *pParam;
; 60   :     LPBYTE ppParam;
; 61   :     __int64 qParam;
; 62   :     } p;
; 63   :      
; 64   : 	
; 65   : 	/* #### PUSH THE PARAMETER ON THE (ASSEMBLER) STACK #### */
; 66   : 	/* Start with last arg first, asm push goes down, not up, so first push must
; 67   :        be the last arg. On entry, if param == params_start, it means NO params
; 68   :        so if there is 1 param,  param will be pointing the struct after the
; 69   :        last one, in other words, param will be a * to an uninit APIPARAM,
; 70   :        therefore -- it immediatly */
; 71   : 	while(param > params_start) {

	cmp	param, params_start
	ja	SHORT loop_body

; 133  : 			};
; 134  : #elif (defined(__GNUC__))
; 146  : #endif /* VC VS GCC */
; 147  : 
; 148  : 			break;
; 149  : 
; 155  : 		}
; 156  : 	}
; 157  : 
; 158  : 	/* #### NOW CALL THE FUNCTION #### */
; 159  : 	//todo, copy retval->t to a c auto, do switch on test c auto, switch might optimize
; 160  :         //to being after the call instruction
; 161  :     {
; 162  :     unsigned char t = control->out;
; 163  :     switch(t WIN32_API_DEBUGM( & ~T_FLAG_UNSIGNED) ) { //unsign has no special treatment here
	;use no C stack *s after call, they might be corrupt on a prototype mistake
	mov	retval, DWORD PTR _retval$[ebp] ;edi is retval
	call	DWORD PTR [esi+8] ; esi is var control
	movzx	ecx, BYTE PTR [esi+3] ; return type, can't use eax or edx
	sub	ecx, T_FLOAT
	je	SHORT get_float
	dec	ecx
	je	SHORT get_double

	; EAX EDX returner (an integer)
	mov	DWORD PTR [retval], eax
	mov	DWORD PTR [retval+4], edx
	jmp	SHORT cleanup

get_double:
	fstp	QWORD PTR [retval]
	jmp	SHORT cleanup

get_float:
	fstp	DWORD PTR [retval]

cleanup:
; 274  : {
; 275  :     unsigned int stack_unwind = (control->whole_bf >> 6) & 0x3FFFC;

	mov	eax, DWORD PTR [esi]
	shr	eax, 6
	and	eax, 3FFFCh

; 276  : #if (defined(_MSC_VER) || defined(__BORLANDC__))
; 277  :     _asm {
; 278  :         add esp, stack_unwind

	add	esp, eax
	; when C stack corruption, edi and esi will be restored with garbage
	; but we dont care since we dont return to caller, also balance stack
	; for ebp esp comparison later
	pop     edi
	pop     esi
	; this only detects stdcall vs cdecl mistakes, and wrong num of params
	; on stdcall, it does NOT detect wrong number of params for cdecl
	; that is more complicated, and random to detect, the only way to detect
	; it with a long security cookie infront of the stack params, and even
	; then, there is no guarentee the compiler or func being called will
	; assign to incoming arg stack slots (infront of the return address)
	; automatically detecting a read would be very difficult, and would
	; require swapping C stacks, and position a NO_ACCESS page right
	; infront of C stack params, bulk88 doesnt think there is any interest
	; in this idea
	cmp     ebp, esp
	jnz     SHORT bad_esp
; 279  :     };
; 280  : #elif (defined(__GNUC__))
; 289  : #endif
; 290  : }
; 291  : }
	;leave ; get C stack working again, if ESP is too high, doing the call
	; will corrupt our retaddr or our saved esi, or caller's vars, techincally
	; this leave will fix the corrupt esp problem and allow execution to
	; resume
	pop     ebp
	ret	8
	
	bad_esp:
	call    DWORD PTR __imp__IsDebuggerPresent@0
	test    eax, eax
	jnz     break
	push    esp ;esp must be always first, since the push modifies esp, after
	;sampling its value
	push    ebp
	push    OFFSET FLAT:_bad_esp_msg ;defined in C for preprocessor
IFDEF PERL_IMPLICIT_CONTEXT ;complicated but seems to work to pass C defs to
	; ASM. The alternative is define a const C void * that does = to the
	; Perl croak_nocontext macro, which on no-thread perl is defed to Perl_croak
	call    DWORD PTR __imp__Perl_croak_nocontext
ELSE
	call    DWORD PTR __imp__Perl_croak ;no pTHX_ in unthreaded perl, so Perl_croak_nocontext doesn't exist
ENDIF
break:
	db 0Fh
	db 0Bh
	; an int 3 can resume exec, a ud2 cant
	; no return
@Call_asm@16 ENDP
__alloca_probe PROC NEAR
    neg     eax
    add     eax, esp
    and     al, 0F0h ;align to 16
    ;add     eax, 4
    xchg    eax, esp
    ;jmp     dword ptr [eax] ; 0.2 us slower
    mov     eax, [eax]
    push    eax
    retn
__alloca_probe ENDP
_TEXT	ENDS
END
