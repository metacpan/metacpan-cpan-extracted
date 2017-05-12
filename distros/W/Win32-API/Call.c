/*will tailcall on GCC, VC does not tailcall (jmp), inline on VC since its more efficient
in instruction size (0x010 bytes less) and copying every twice to C stack*/
//#ifdef _MSC_VER
//__forceinline
//#endif
void __stdcall callPack(pTHX_ const APICONTROL * control, APIPARAM * param, SV * sv, int func_offset){
	param = (APIPARAM *)AvARRAY(control->intypes)[param->idx0];
	control = (APICONTROL *)control->api;
	pointerCall3Param(aTHX_ (SV *)control, (SV*)param, sv, func_offset);
}

SV * getSentinal(pTHX) {
    dMY_CXT;
    return MY_CXT.sentinal;
}

/*on VC2003 PL_stack_base[(size_t)ax_i/sizeof(SV*)]; the >>2 and <<2 dont optimize away in -O1
mov     ebx, [ebp+ax_i]
mov     ecx, [esi+0Ch]
shr     ebx, 2
shl     ebx, 2
mov     edi, [ecx+ebx]
   Special version of ST() macro whose x parameter is in units of "sizeof(SV *)".
   This saves a *4 or *8 on x */
#define W32A_ST(x) *(SV**)((size_t)PL_stack_base+(size_t)(x))
#define IS_CALL sizeof(SV *) // must be SV *, subbed from a SV **
#define NEEDS_POST_CALL_LOOP 0x1

/*all callbacks in Call() that use Call()'s SP (not a dSP SP)
 must call SPAGAIN after the ENTER, incase of a earlier callback
 that caused a stack reallocation either in Call() or a helper,
 do NOT use Call()'s SP without immediatly previously doing a SPAGAIN
 Call()'s SP in general is "dirty" at all times and can't be used without
 a SPAGAIN, things that do callbacks DO NOT update Call()'s SP after the
 call_*
 also using the PPCODE: SP will corrupt the stack, SPAGAIN will get the end
 of params SP, not start of params SP, a SPAGAIN undoes the XPREPUSH
 so always use SPAGAIN before any use of Call()'s SP
 idealy _alloca and OrigST should be removed one day and SP is at all times
 clean for use, and a unshift or *(SP+X) is done instead of the ST() macro
 to get the incoming params
 update above /|\
 */

/* SPLIT_HEAD is only for compilers that will optimize to a jmp, not a call,
   none on 32 bits known right now*/

//#define W32A_SPLITHEAD

#ifndef W32A_SPLITHEAD

XS(XS_Win32__API_ImportCall);
#if defined(_MSC_VER) && ! (defined(_M_AMD64) || defined(__x86_64))
__declspec(naked) XS(XS_Win32__API_Call) {
    __asm {
#ifdef PERL_IMPLICIT_CONTEXT
    or dword ptr [esp+8], 1h
#else
    or dword ptr [esp+4], 1h
#endif
    jmp XS_Win32__API_ImportCall
    }
}
#else
XS(XS_Win32__API_Call) {
    XS_Win32__API_ImportCall(aTHX_ (CV*)((size_t)cv | 1));
}
#endif //XS_Win32__API_Call definined in MASM or not

XS(XS_Win32__API_ImportCall)
{
#if defined(_MSC_VER) && ! (defined(_M_AMD64) || defined(__x86_64))
    void * origesp;
    __asm {
        mov origesp, esp
    }
#endif
#if defined(_M_AMD64) || defined(__x86_64)
    WIN32_API_PROFF(QueryPerformanceFrequency(&my_freq));
#endif
    WIN32_API_PROFF(W32A_Prof_GT(&start));
{
    dVAR;
    SV ** ax_p = (SV **)((size_t)(POPMARK)*sizeof(SV *)); /*ax_p = pointer, not the normal ax */
    if (PL_markstack_ptr+1 == PL_markstack_max)
    markstack_grow();
    {
    dSP;
    EXTEND(SP,CALL_PL_ST_EXTEND);//the one and only EXTEND, all users must
     //static assert against the constant
    {//compiler can toss some variables that EXTEND used
    SV **mark = &(W32A_ST(ax_p));
    SV ** items_sv = (SV **)((size_t)sp - (size_t)mark);
    ax_p++;
    PERL_UNUSED_VAR(cv); /* -W */
    {
    APIPARAM *params;
    const APICONTROL * control;
    APIPARAM * param;
    size_t param_len;

    AV*		pparray;
    SV**	ppref;

	SV** code;

    int nin;
    SV ** ax_end;
    long_ptr tin;
    unsigned int rt_flags;
    SV * sentinal;
    if(!(rt_flags = (size_t)cv & 1))  /* ::Import(, placed here so jmp taken is ->Call(*/
    {
        rt_flags = 0;
        control = (const APICONTROL *)XSANY.any_ptr;
    }
    //if(!XSANY.any_ptr){ /* ->Call( */
    else {
        SV*	api;
        *(size_t*)&cv  ^= rt_flags;
        if (items_sv  == 0)
            croak_xs_usage(cv,  "api, ...");
        api = W32A_ST(ax_p);
        items_sv--; /* make ST(0)/api obj on Perl Stack disapper */
        ax_p++;
        rt_flags = IS_CALL;
        control = (APICONTROL *) SvPVX(SvRV(api));
    }



#else //is W32A_SPLITHEAD
STATIC void Call_body(pTHX_ const APICONTROL * const control, unsigned int rt_flags, SV ** ax_p,
          SV ** items_sv);
/*-------------------------------------------------------------------*/
XS(XS_Win32__API_ImportCall)
{
#if defined(_M_AMD64) || defined(__x86_64)
    WIN32_API_PROFF(QueryPerformanceFrequency(&my_freq));
#endif
    WIN32_API_PROFF(W32A_Prof_GT(&start));
{
    dVAR;
    SV ** ax_p = (SV **)((size_t)(POPMARK)*sizeof(SV *)); /*ax_p = pointer, not the normal ax */
    if (PL_markstack_ptr+1 == PL_markstack_max)
    markstack_grow();
    {
    dSP;
    EXTEND(SP,CALL_PL_ST_EXTEND);//the one and only EXTEND, all users must
     //static assert against the constant
    {//compiler can toss some variables that EXTEND used
    SV **mark = &(W32A_ST(ax_p));
    SV ** items_sv = (size_t)sp - (size_t)mark;
    ax_p++;
    PERL_UNUSED_VAR(cv); /* -W */
    Call_body(aTHX_ (const APICONTROL *)XSANY.any_ptr, 0, ax_p, items_sv);
    }
    }
}
}
XS(XS_Win32__API_Call)
{
#if defined(_M_AMD64) || defined(__x86_64)
    WIN32_API_PROFF(QueryPerformanceFrequency(&my_freq));
#endif
    WIN32_API_PROFF(W32A_Prof_GT(&start));
{
    dVAR;
    SV ** ax_p = (SV **)((size_t)(POPMARK)*sizeof(SV *)); /*ax_p = pointer, not the normal ax */
    if (PL_markstack_ptr+1 == PL_markstack_max)
    markstack_grow();
    {
    dSP;
    EXTEND(SP,CALL_PL_ST_EXTEND);//the one and only EXTEND, all users must
     //static assert against the constant
    {//compiler can toss some variables that EXTEND used
    SV **mark = &(W32A_ST(ax_p));
    SV ** items_sv = (size_t)sp - (size_t)mark;
    SV*	api;
    ax_p++;
    if (items_sv  == 0)
        croak_xs_usage(cv,  "api, ...");
    api = W32A_ST(ax_p);
    items_sv--; /* make ST(0)/api obj on Perl Stack disapper */
    ax_p++;
    Call_body(aTHX_ (APICONTROL *) SvPVX(SvRV(api)), IS_CALL, ax_p, items_sv);
    }
    }
    }
    
}

STATIC void Call_body(pTHX_ const APICONTROL * const control, unsigned int rt_flags, SV ** ax_p,
          SV ** items_sv) {
#if defined(_MSC_VER) && ! (defined(_M_AMD64) || defined(__x86_64))
    void * origesp;
    __asm {
        mov origesp, esp
    }
#endif
    {
    dVAR;
    dSP;
    APIPARAM *params;
    APIPARAM * param;
    size_t param_len;

    AV*		pparray;
    SV**	ppref;

	SV** code;

    int nin;
    SV ** ax_end;
    long_ptr tin;
    SV * sentinal;
#endif //#ifndef W32A_SPLITHEAD
    {
    if(items_sv != (SV**)(control->inparamlen)) { /* both in units of sizeof(SV*) */
        croak("Wrong number of parameters: expected %d, got %d.\n"
              ,(size_t)control->inparamlen / sizeof(SV*)
              ,(size_t)items_sv / sizeof(SV*));
    }
    nin = (size_t)control->inparamlen / sizeof(SV*);
    }
    /*take advantage of a zero flag modification*/
    if(param_len=control->inparamlen * (sizeof(APIPARAM)/sizeof(SV*))) {
        SV ** ax_i;
#ifdef WIN32_API_DEBUG
        int i;
#endif
        WIN32_API_PROFF(W32A_Prof_GT(&loopprep));
        sentinal = NULL;
        /* a note about Perl stack operations below, we write replace SV *s on
           the Perl stack in some cases where the SV * the user passed in can't
           be used or we aren't interested in it but some other SV * after
           Call_asm(), so the ST() slots ARENT always what the caller passed in
        */
#if !(defined(_MSC_VER) && ! (defined(_M_AMD64) || defined(__x86_64)))
        params = (APIPARAM *) _alloca(param_len);
        memcpy(params, &(control->param), param_len);
#else
/*
        __asm {
            //and     sp, 0FFF0h //align to 16, never do this, eax math is faster by 4-10 ns
            mov eax, esp
            and al, 0F0h //align esp to 16
            sub eax, param_len
            mov esp, eax
            mov params, eax
        }
*/
        // SSE copying, unknown if i386 or SSE copying is faster
 /*       {
            __m128i * param_dst = (__m128i *)params;
            __m128i * param_src = (__m128i *)&(control->param);
            __m128i * params_end = (__m128i *)((size_t)&(control->param)+param_len);
            do {
                *param_dst = *param_src;
                param_src++;
                param_dst++;
            } while (param_src != params_end);
        }
        {
            __int64 * param_dst = (__int64 *)params;
            __int64 * param_src = (__int64 *)&(control->param);
            __int64 * params_end =(__int64 *)((size_t)&(control->param)+(size_t)(param_len));
            do {
                //todo, make it copy 16 bytes in 1 loop pass, not 8
                *param_dst = *param_src;
                param_src++;
                param_dst++;
            } while (param_src != params_end);
        }*/
        //below is fastest on VC2003 + Intel Merom (Core 2)
        {
            void * end_ptr = (void *)param_len;
            void * source_ptr = (void *)((size_t)&(control->param)+(size_t)param_len-16);
        __asm {
            mov eax, esp
            and al, 0F0h /* align esp to 16*/
            mov esp, eax
            mov ecx, source_ptr
            sub eax, end_ptr /* calc lower end of APIPARAM array */
            copy_loop:
            push dword ptr [ecx+12]
            push dword ptr [ecx+8]
            push dword ptr [ecx+4]
            push dword ptr [ecx]
            cmp esp, eax
            lea ecx, [ecx-16]
            jne copy_loop
            mov params, eax
        }
        }
#endif /* optimized alloca and memcpy for MSVC*/

        /* #### FIRST PASS: initialize params #### */
        /* this is a combo of a do-while and a for loop, going from ax start
          of incoming args to ax end of incoming args, << 2/<< 3 avoided then */
        ax_i=ax_p;
        ax_end = (SV **)((size_t)ax_p
                         +(size_t)(param_len / (sizeof(APIPARAM)/sizeof(SV *)))); //move me up
        param = params;
#ifdef WIN32_API_DEBUG
        i=0;
#endif
        WIN32_API_PROFF(W32A_Prof_GT(&loopstart));
        incoming_loop:
        {
            SV*     pl_stack_param;
            tin = param->t;
            pl_stack_param = W32A_ST(ax_i);
        /* note T_SHORT is not in this jumptable on purpose, see type_to_num,
           +1 is to remove T_VOID hole in compiler's jumptable, there is a -1 in
           API::new() to match, the +1 is optimized away by -1'ing the case constants*/
            switch(tin+1) {
            case T_NUMBER:
				param->l = (long_ptr) SvIV(pl_stack_param);  //xxx not sure about T_NUMBER length on Win64
#ifdef WIN32_API_DEBUG
				printf("(XS)Win32::API::Call: params[%d].t=%d, .u=%ld\n", i, params[i].t, params[i].l);
#endif
                break;
#ifdef T_QUAD
            case T_QUAD:{
#ifdef USEMI64
                __int64 * pI64;
                if(control->UseMI64 || SvROK(pl_stack_param)){
                    SPAGAIN;
					W32APUSHMARK(SP);
                    STATIC_ASSERT(CALL_PL_ST_EXTEND >= 1);
                    PUSHs(pl_stack_param); //currently mortal, came from caller
                    PUTBACK;
#if defined(DEBUGGING) || ! defined (NDEBUG)
                    PUSHs(NULL);//poison the stack the PUSH above only overwrites->
                    PUSHs(NULL);//the api obj
                    PUSHs(NULL);
                    PUSHs(NULL);
#endif
                     //don't check return count, assume its 1
                    call_pv("Math::Int64::int64_to_native", G_SCALAR);
                    SPAGAIN;//un/signed MI64 call irrelavent bulk88 thinks
                    pl_stack_param = POPs; //this is also mortal
                }
                pI64 = (__int64 *) SvPV_nolen(pl_stack_param);
                if(SvCUR(pl_stack_param) != 8)
                croak("Win32::API::Call: parameter %d must be a%s",param->idx1, " packed 8 bytes long string, it is a 64 bit integer (Math::Int64 broken?)");
				param->q = *pI64;
#else
                param->q = (__int64) SvIV(pl_stack_param);
#endif //USEMI64
#ifdef WIN32_API_DEBUG
				printf("(XS)Win32::API::Call: params[%d].t=%d, .u=%I64d\n", i, params[i].t, params[i].q);
#endif
                }break;
#endif
            case T_CHAR:{
                char c;
                //this might be the "overflowed" null char that is after each PV buffer
                c = (SvPV_nolen(pl_stack_param))[0];
                //zero/sign extend bug? not sure about 32bit call conv, google
                //says promotion, VC compiler in Od in api_test.dll ZX/SXes
                //x64 is garbage extend
                param->l = (long_ptr)(c);
#ifdef WIN32_API_DEBUG
				printf("(XS)Win32::API::Call: params[%d].t=%d,  as char .u=%c\n", i, params[i].t, (char)params[i].l);
#endif
                }break;
            case T_NUMCHAR:{
                char c;
                //unreachable unless had a proto in Perl
                c = (char) SvIV(pl_stack_param);
                param->l = (long_ptr)(c);
#ifdef WIN32_API_DEBUG
				printf("(XS)Win32::API::Call: params[%d].t=%d, as num  .u=0x%X\n", i, params[i].t, (unsigned char) SvIV(pl_stack_param));
#endif
                }break;
            case T_FLOAT:
               	param->f = (float) SvNV(pl_stack_param);
#ifdef WIN32_API_DEBUG
                printf("(XS)Win32::API::Call: params[%d].t=%d, .u=%f\n", i, params[i].t, params[i].f);
#endif
                break;
            case T_DOUBLE:
               	param->d = (double) SvNV(pl_stack_param);
#ifdef WIN32_API_DEBUG
               	printf("(XS)Win32::API::Call: params[%d].t=%d, .u=%f\n", i, params[i].t, params[i].d);
#endif
                break;
            case T_POINTER:{
                //Not COW compliant Todo
                if(SvREADONLY(pl_stack_param)) //Call() param was a string litteral
                    W32A_ST(ax_i) = pl_stack_param = sv_mortalcopy(pl_stack_param);
                if(control->has_proto) {
                    if(SvOK(pl_stack_param)) {
                        if(control->is_more) {
                            callPack(aTHX_ control, param, pl_stack_param, PARAM3_PACK);
                            //pointerCall3Param(aTHX_ control->api, AvARRAY(control->intypes)[i], pl_stack_param, PARAM3_PACK );
                        }
                        goto PTR_IN_USE_PV;
                    /* When arg is undef, use NULL pointer */
                    } else {
                        assert(!param->p); /*param arr is null filled by the memcpy from template */
                    }
				} else {
					if(SvIOK(pl_stack_param) && SvIV(pl_stack_param) == 0) {
                        assert(!param->p);
					} else {
                        PTR_IN_USE_PV: //todo, check for sentinal before adding, decow?
                        if(!sentinal) sentinal = getSentinal(aTHX);
                        sv_catsv(pl_stack_param, sentinal);
                        param->p = SvPVX(pl_stack_param);
                        rt_flags |= NEEDS_POST_CALL_LOOP;;
					}
				}
#ifdef WIN32_API_DEBUG
                printf("(XS)Win32::API::Call: params[%d].t=%d, .p=%s .l=%X\n", i, params[i].t, params[i].p, params[i].p);
#endif
                break;
            }
            case T_POINTERPOINTER:
                rt_flags |= NEEDS_POST_CALL_LOOP;
                if(SvROK(pl_stack_param) && SvTYPE(SvRV(pl_stack_param)) == SVt_PVAV) {
                    pparray = (AV*) SvRV(pl_stack_param);
                    ppref = av_fetch(pparray, 0, 0);
                    if(SvIOK(*ppref) && SvIV(*ppref) == 0) {
                        assert(!param->b);
                    } else {
                        param->b = (LPBYTE) SvPV_nolen(*ppref);
                    }
#ifdef WIN32_API_DEBUG
                    printf("(XS)Win32::API::Call: params[%d].t=%d, .u=%s\n", i, params[i].t, params[i].p);
#endif
                } else {
                    croak("Win32::API::Call: parameter %d must be a%s",param->idx1, "n array reference!\n");
                }
                break;
            case T_INTEGER:
                param->l = (long_ptr) (int) SvIV(pl_stack_param);
#ifdef WIN32_API_DEBUG
                printf("(XS)Win32::API::Call: params[%d].t=%d, .u=%d\n", i, params[i].t, params[i].l);
#endif
                break;

            case T_STRUCTURE:
				{
					MAGIC* mg;
                    rt_flags |= NEEDS_POST_CALL_LOOP;
					if(SvROK(pl_stack_param) && SvTYPE(SvRV(pl_stack_param)) == SVt_PVHV) {
						mg = mg_find(SvRV(pl_stack_param), 'P');
						if(mg != NULL) {
#ifdef WIN32_API_DEBUG
							printf("(XS)Win32::API::Call: SvRV(ST(i+1)) has P magic\n");
#endif
							W32A_ST(ax_i) = pl_stack_param = mg->mg_obj; //inner tied var
						}
                        if(!sv_isobject(pl_stack_param)) goto Not_a_struct;
                        {
						SV** buffer;
						//int count;

						/*
						ENTER;
						SAVETMPS;
						PUSHMARK(SP);
						XPUSHs(sv_2mortal(newSVsv(structs[i].object)));
						PUTBACK;

						count = call_method("sizeof", G_SCALAR);

						SPAGAIN;
						structs[i].size = POPi;
						PUTBACK;

						FREETMPS;
						LEAVE;
						*/
						if(control->has_proto){ //SVt_PVHV check done earlier, passing a fake
		//hash ref obj should work, if it doesn't have the right hash slice
		//thats not ::APIs responsbility
							pointerCall3Param(aTHX_
		*hv_fetch((HV *)SvRV(pl_stack_param), "__typedef__", sizeof("__typedef__")-1, 0),
		AvARRAY(control->intypes)[param->idx0],       sv_2mortal(newSViv(param->idx1)),       PARAM3_CK_TYPE);
						}
						SPAGAIN;
						W32APUSHMARK(SP);
						STATIC_ASSERT(CALL_PL_ST_EXTEND >= 1);
						PUSHs(pl_stack_param);
						PUTBACK;
						call_method("Pack", G_DISCARD);

						buffer = hv_fetch((HV*) SvRV(pl_stack_param), "buffer", 6, 0);
						if(buffer != NULL) {
							param->p = (char *) (LPBYTE) SvPV_nolen(*buffer);
						} else {
							assert(!param->p);
						}
#ifdef WIN32_API_DEBUG
						printf("(XS)Win32::API::Call: params[%d].t=%d, .u=%s (0x%08x)\n", i, params[i].t, params[i].p, params[i].p);
#endif
                        }
					}/* is an RV to HV */
                    else {
                        Not_a_struct:
                    	croak("Win32::API::Call: parameter %d must be a%s", param->idx1, " Win32::API::Struct object!\n");
                    }
				}
                break;

			case T_CODE:
#ifdef WIN32_API_DEBUG
				printf("(XS)Win32::API::Call: got a T_CODE, (SV=0x%08x) (SvPV='%s')\n", pl_stack_param, SvPV_nolen(pl_stack_param));
#endif
				if(SvROK(pl_stack_param)) {
#ifdef WIN32_API_DEBUG
				printf("(XS)Win32::API::Call: fetching code...\n");
#endif
					code = hv_fetch((HV*) SvRV(pl_stack_param), "code", 4, 0);
					if(code != NULL) {
						param->l = SvIV(*code);
					} else { goto Not_a_callback;
					}
				} else {
                    Not_a_callback:
					croak("Win32::API::Call: parameter %d must be a%s", param->idx1, " Win32::API::Callback object!\n");
				}
				break;
            default:
                croak("Win32::API::Call: (internal error) unknown type %u\n", tin);
                break;
            } /* incoming type switch */
            ax_i++;
            param++;
            if(ax_i < ax_end){
#ifdef WIN32_API_DEBUG
                i++;
#endif
                goto incoming_loop;
            }
        }/* incoming_loop */
    } /* if incoming args */
    else {param = params;}
    /* call_asm x86 compares uninit+0 == uninit before derefing, so params
     being set to NULL is optional */
    WIN32_API_PROFF(W32A_Prof_GT(&Call_asm_b4));
    {//call_asm scope
#ifdef WIN64
        APIPARAM retval;
        retval.t = control->out & ~T_FLAG_NUMERIC; //flag numeric not in ASM
		Call_asm(control->ApiFunction, params, nin, &retval);
#else
        APIPARAM_U retval; /* t member not needed on 32 bit implementation*/
        /* a 0 unwind can be stdcall or cdecl, a true unwind can only be cdecl */
        assert(control->stackunwind * 4 ? (control->convention == APICONTROL_CC_C): 1);
		Call_asm(param, params, control, &retval);
#endif
    WIN32_API_PROFF(W32A_Prof_GT(&Call_asm_after));
	/* #### THIRD PASS: postfix pointers/structures #### */
	if(rt_flags & NEEDS_POST_CALL_LOOP) {
#ifdef WIN32_API_DEBUG
        int i = 0;
#endif
        SV ** ax_i;
        ax_i=ax_p;
        //ax_end set earlier
        param = params;
        post_call_incoming_loop:
        {
        SV * sv = W32A_ST(ax_i);
        switch(param->t){
        case T_POINTER-1:
            if(param->p) {
            char * sen = SvPVX(sentinal);
            char * end = SvEND(sv);
            end -= (sizeof(SENTINAL_STRUCT));
            //todo replace with inline comparison
            if(memcmp(end, sen, sizeof(SENTINAL_STRUCT))){
                HV * env = get_hv("ENV", GV_ADD);
                SV ** buf_check = hv_fetchs(env, "WIN32_API_SORRY_I_WAS_AN_IDIOT", 0);
                if(buf_check && sv_true(*buf_check)) {0;}
                else{croak("Win32::API::Call: parameter %d had a buffer overflow", param->idx1);}
            }else{ //remove the sentinal off the buffer
                SvCUR_set(sv, SvCUR(sv)-sizeof(SENTINAL_STRUCT));
            }
            /* bad VC optimizer && is always a branch, so dont use bf members*/
            if((*(char *)&(control->whole_bf)
                & (CTRL_IS_MORE|CTRL_HAS_PROTO))
               == (CTRL_IS_MORE|CTRL_HAS_PROTO)){
                callPack(aTHX_ control, param, sv, PARAM3_UNPACK);
                //pointerCall3Param(aTHX_ control->api, AvARRAY(control->intypes)[i], sv, PARAM3_UNPACK );
            }
            } //if(param->p) {
            break;
		case T_STRUCTURE-1:
            SPAGAIN;
			W32APUSHMARK(SP);
            STATIC_ASSERT(CALL_PL_ST_EXTEND >= 1);
			PUSHs(sv);
			PUTBACK;

			call_method("Unpack", G_DISCARD);
            break;
        case T_POINTERPOINTER-1:
            pparray = (AV*) SvRV(sv);
            av_extend(pparray, 2);
            av_store(pparray, 1, newSViv(*(param->b)));
            break;
#ifndef NDEBUG
	default:
#  ifdef T_QUAD
	    if(param->t > T_QUAD)
#  else
	    if(param->t > T_DOUBLE)
#  endif
		croak("Win32::API::Call: (internal error) unknown type %u\n", param->t);
#endif
        } //end of switch
        ax_i++;
        param++;
        if(ax_i < ax_end){
#ifdef WIN32_API_DEBUG
            i++;
#endif
            goto post_call_incoming_loop;
        }
        }/* var sv from PL stack scope */
    }
    /* if(rt_flags & NEEDS_POST_CALL_LOOP) */
#ifdef WIN32_API_DEBUG
   	printf("(XS)Win32::API::Call: returning to caller t=%u.\n", control->out);
#endif
	/* #### NOW PUSH THE RETURN VALUE ON THE (PERL) STACK #### */
    SP = &(W32A_ST(ax_p)); /* XSprePUSH equivelent -1 not needed b/c always ret 1 elem*/
    SP = (SV **)((DWORD_PTR)SP - (DWORD_PTR)(rt_flags & IS_CALL)); /* IS_CALL flag is sizeof(SV *)*/
    PUTBACK;
    if(control->out == T_VOID){
        return_undef:
#ifdef WIN32_API_DEBUG
	   	printf("(XS)Win32::API::Call: returning UNDEF.\n");
#endif
        *SP = &PL_sv_undef;
        goto _return; /*dont call SvSETMAGIC or use TARG */
    }
    {//tout scope
    dXSTARG; /* todo, dont execute for returning undef */
    //un/signed prefix is ignored unless implemented, T_FLAG_NUMERIC is removed in API.pm
    *SP = TARG;
    switch(control->out) {
    case T_NUMBER:
#ifdef WIN32_API_DEBUG
	   	printf("(XS)Win32::API::Call: returning T_NUMBER %Id.\n", retval.l);
#endif
        sv_setiv(TARG, retval.l);
        break;
    case (T_NUMBER|T_FLAG_UNSIGNED):
#ifdef WIN32_API_DEBUG
	   	printf("(XS)Win32::API::Call: returning %Iu.\n", retval.ul);
#endif
        sv_setuv(TARG, retval.ul);
        break;
    case T_INTEGER:
#ifdef WIN32_API_DEBUG
	   	printf("(XS)Win32::API::Call: returning  T_INTEGER %d.\n", (int)retval.l);
#endif
        sv_setiv(TARG, (IV)(int)retval.l);
        break;
    case (T_INTEGER|T_FLAG_UNSIGNED):
#ifdef WIN32_API_DEBUG
	   	printf("(XS)Win32::API::Call: returning T_INTEGER|T_FLAG_UNSIGNED %u.\n", (unsigned int)retval.ul);
#endif
        sv_setuv(TARG, (UV)(unsigned int)retval.ul);
        break;
    case T_SHORT:
#ifdef WIN32_API_DEBUG
	   	printf("(XS)Win32::API::Call: returning %hd.\n", retval.l);
#endif
        sv_setiv(TARG, (IV)(short)retval.l);
        break;
    case (T_SHORT|T_FLAG_UNSIGNED):
#ifdef WIN32_API_DEBUG
	   	printf("(XS)Win32::API::Call: returning %hu.\n", retval.ul);
#endif
        sv_setuv(TARG, (UV)(unsigned short)retval.ul);
        break;
#ifdef T_QUAD
#ifdef USEMI64
    case T_QUAD:
    case (T_QUAD|T_FLAG_UNSIGNED):
#ifdef WIN32_API_DEBUG
	   	printf("(XS)Win32::API::Call: returning %I64d.\n", retval.q);
#endif
        sv_setpvn(TARG, (char *)&retval.q, sizeof(retval.q));
        if(control->UseMI64){
            const static struct {
                char _signed [sizeof("Math::Int64::native_to_int64")];
                char _unsigned [sizeof("Math::Int64::native_to_uint64")];
            } MI64RetSubName = {
                "Math::Int64::native_to_int64",
                "Math::Int64::native_to_uint64"
            };
            /*TARG already on PL stack, put mark behind TARG slice*/
			W32APUSHMARK(SP-1);
            STATIC_ASSERT(CALL_PL_ST_EXTEND >= 1);
            /* branchless string selection, result of & is either 0 or offset to start of unsigned sub name*/
            call_pv(MI64RetSubName._signed + (size_t)(
                    -!!(control->out & T_FLAG_UNSIGNED)
                    & ((char *)(&MI64RetSubName._unsigned) - (char*)(&MI64RetSubName._signed)))
                    , G_SCALAR);
            goto _return; /* global SP is 1 ahead */
        }
        break;
#else //USEMI64
    case T_QUAD:
#ifdef WIN32_API_DEBUG
	   	printf("(XS)Win32::API::Call: returning %I64d.\n", retval.q);
#endif
        sv_setiv(TARG, retval.q);
        break;
    case (T_QUAD|T_FLAG_UNSIGNED):
#ifdef WIN32_API_DEBUG
	   	printf("(XS)Win32::API::Call: returning %I64d.\n", retval.q);
#endif
        sv_setuv(TARG, retval.q);
        break;
#endif //USEMI64
#endif //T_QUAD
    case T_FLOAT:
#ifdef WIN32_API_DEBUG
	   	printf("(XS)Win32::API::Call: returning %f.\n", retval.f);
#endif
        sv_setnv(TARG, (double) retval.f);
        break;
    case T_DOUBLE:
#ifdef WIN32_API_DEBUG
	   	printf("(XS)Win32::API::Call: returning %f.\n", retval.d);
#endif
        sv_setnv(TARG, retval.d);
        break;
    case T_POINTER:
		if(retval.p == NULL) {
#ifdef WIN32_API_DEBUG
	   	printf("(XS)Win32::API::Call: returning NULL.\n");
#endif
            RET_PTR_NULL:
            if(!control->is_more) sv_setiv(TARG, 0);
            else goto return_undef; //undef much clearer, IV 0 is for back compat reasons
		} else {
#ifdef WIN32_API_DEBUG
		printf("(XS)Win32::API::Call: returning 0x%x '%s'\n", retval.p, retval.p);
#endif
            //The user is probably leaking, new pointers are almost always
            //caller's responsibility
            if(IsBadStringPtr(retval.p, ~0)) goto RET_PTR_NULL;
            else {
                sv_setpv(TARG, retval.p);
            }
	    }
        break;
    case T_CHAR:
    case (T_CHAR|T_FLAG_UNSIGNED):
#ifdef WIN32_API_DEBUG
	   	printf("(XS)Win32::API::Call: returning char 0x%X .\n", (char)retval.l);
#endif
        sv_setpvn(TARG, (char *)&retval.l, 1);
        break;
    case T_NUMCHAR:
#ifdef WIN32_API_DEBUG
	   	printf("(XS)Win32::API::Call: returning numeric char %hd.\n", (char)retval.l);
#endif
        sv_setiv(TARG, (IV)(char)retval.l);
        break;
    case (T_NUMCHAR|T_FLAG_UNSIGNED):
#ifdef WIN32_API_DEBUG
	   	printf("(XS)Win32::API::Call: returning numeric unsigned char %hu.\n", (unsigned char)retval.l);
#endif
        sv_setuv(TARG, (UV)(unsigned char)retval.ul);
        break;
    default:
        croak("Win32::API::Call: (internal error) unknown type %u\n", control->out);
    }
    SvSETMAGIC(TARG);

    _return:
    WIN32_API_PROFF(W32A_Prof_GT(&return_time));
    WIN32_API_PROFF(W32A_Prof_GT(&return_time2));
    /*
    WIN32_API_PROFF(printf("freq %I64u start %I64u loopprep %I64u loopstart %I64u Call_asm_b4 %I64u Call_asm_after %I64u rtn_time %I64u rtn_time2\n",
        my_freq, // 12 is bulk88's Core 2 TSC increment unit, eyes hurt less comparing the numbers
           (loopprep.QuadPart - start.QuadPart - (return_time2.QuadPart-return_time.QuadPart))/12,
           (loopstart.QuadPart - loopprep.QuadPart -(return_time2.QuadPart-return_time.QuadPart))/12,
           (Call_asm_b4.QuadPart - loopstart.QuadPart - (return_time2.QuadPart-return_time.QuadPart))/12,
           (Call_asm_after.QuadPart-Call_asm_b4.QuadPart - (return_time2.QuadPart-return_time.QuadPart))/12,
           (return_time.QuadPart-Call_asm_after.QuadPart - (return_time2.QuadPart-return_time.QuadPart))/12,
           return_time2.QuadPart-return_time.QuadPart
           ));
    */
#ifdef WIN32_API_PROF
    start_loopprep.QuadPart += (loopprep.QuadPart - start.QuadPart - (return_time2.QuadPart-return_time.QuadPart))/12;
    loopprep_loopstart.QuadPart += (loopstart.QuadPart - loopprep.QuadPart -(return_time2.QuadPart-return_time.QuadPart))/12;
    loopstart_Call_asm_b4.QuadPart += (Call_asm_b4.QuadPart - loopstart.QuadPart - (return_time2.QuadPart-return_time.QuadPart))/12;
    Call_asm_b4_Call_asm_after.QuadPart += (Call_asm_after.QuadPart-Call_asm_b4.QuadPart - (return_time2.QuadPart-return_time.QuadPart))/12;
    Call_asm_after_return_time.QuadPart += (return_time.QuadPart-Call_asm_after.QuadPart - (return_time2.QuadPart-return_time.QuadPart))/12;
    printf("start %I64u loopprep %I64u loopstart %I64u Call_asm_b4 %I64u Call_asm_after %I64u rtn_time\n",
           start_loopprep.QuadPart, loopprep_loopstart.QuadPart, loopstart_Call_asm_b4.QuadPart, Call_asm_b4_Call_asm_after.QuadPart, Call_asm_after_return_time.QuadPart);
#endif

    //*/
#if defined(_MSC_VER) && ! (defined(_M_AMD64) || defined(__x86_64))
    __asm {
        mov esp, origesp
    }
#endif
    return; /* don't use CODE:'s boilerplate */
    }//tout scope
    }//call_asm scope
    }
#ifndef W32A_SPLITHEAD
    }
    }
    }
#endif
}
#undef W32AST
