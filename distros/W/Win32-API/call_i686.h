
/*
   "I have a dream."
   Define one assembler macro for everyone: gcc, Borland C & MSVC
   Is it possible?
*/

/* The code in this file is not used anymore since each CC has its own asm
   version.

   The code below will compile under MSVC can be used to generate boilerplate for
   the MASM code, but the ASM versions are more efficient, this file is #included
   twice, once in API.xs and once (if applicable) in call_i686.c
   */
#if 0

PORTALIGN(1) const char bad_esp_msg [];

/* Borland C */
#if (defined(__BORLANDC__) && __BORLANDC__ >= 452)
    #define ASM_LOAD_EAX(param,type) \
        __asm {                      \
            mov    eax, type param ; \
            push   eax             ; \
        }
/* MSVC compilers */
#elif defined _MSC_VER
    /* Disable warning about one missing macro parameter.
       TODO: How we define a macro with an optional (empty) parameter? */
    #pragma warning( disable : 4003 )
    #define ASM_LOAD_EAX(param,type) { \
    	__asm { mov eax, type param }; \
    	__asm { push eax };            \
    }
/* GCC-MinGW Compiler */
#elif (defined(__GNUC__))
    #define ASM_LOAD_EAX(param,...)  asm ("push %0" :: "g" (param));
#endif

#ifdef __GNUC__
#  define GCC_VERSION (__GNUC__ * 10000 \
                     + __GNUC_MINOR__ * 100 \
                     + __GNUC_PATCHLEVEL__)
#  if GCC_VERSION >= 40400
#    pragma GCC push_options
#  endif
#endif

extern void __cdecl _RTC_CheckEsp();



/* params are arranged first used (left) to last used (right) */
#ifdef __cplusplus
extern "C"
#endif
void __fastcall Call_asm(const APIPARAM * param /*in caller, this a * to after the last
                                      initialized struct, on entry, param is
                                      always pointing to uninit memory*/,
              const APIPARAM * const params_start,
              const APICONTROL * const control,
              APIPARAM_U * const retval)
{

    /* int    iParam; */
    union{
    long   lParam;
    float  fParam;
    double dParam;
    /* char   cParam; */
    char  *pParam;
    LPBYTE ppParam;
    __int64 qParam;
    } p;
	register int i = (size_t)param/(size_t)params_start;
	/* #### PUSH THE PARAMETER ON THE (ASSEMBLER) STACK #### */
	/* Start with last arg first, asm push goes down, not up, so first push must
       be the last arg. On entry, if param == params_start, it means NO params
       so if there is 1 param,  param will be pointing the struct after the
       last one, in other words, param will be a * to an uninit APIPARAM,
       therefore -- it immediatly */
/* make gcc not trust ESP */
#ifdef __GNUC__
    void * orig_esp;
    register void * unused_gcc asm ("eax");
    unused_gcc = alloca(1);
    asm ("movl %%esp, %0" : "=g" (orig_esp));
#endif
	while(param > params_start) {
        param--;
        p.qParam = param->q;
		switch(param->t+1) {
/* the 8 byte types are implemented by "pushing the high 4 bytes", then falling
   through to the "push low 4 bytes" that all the other types do */
		case T_DOUBLE:
		case T_QUAD:
#if (defined(_MSC_VER) || defined(BORLANDC))
			__asm {
;very dangerous/compiler specific
;avoiding indirections, *(ebp+offset), then *(reg+offset[0 or 4])
                                push dword ptr [p+4];
			};
#elif (defined(__GNUC__))
        p.qParam = param->q;
	/* probably uglier than necessary, but works */
	asm ("pushl %0":: "g" (((unsigned int*)&p)[1]));
	/* { 
	  int idc;
	  printf ("dParam = ");
	  for (idc = 0; idc < sizeof(dParam); idc++) {
		printf(" %2.2x",((unsigned char*)&dParam)[idc]);
	  } 
	  printf("   %f\n", dParam);
	} */
#endif /* VC VS GCC */
#ifdef WIN32_API_DEBUG
                if(param->t+1 == T_QUAD)
			printf("(XS)Win32::API::Call: parameter %d (Q) is %I64d\n", i, param->q);
                else
			printf("(XS)Win32::API::Call: parameter %d (D) is %f\n", i, param->d);
#endif
//			break; /* end of case T_DOUBLE: case T_QUAD: */

#ifdef WIN32_API_DEBUG
                /* this branch is all the 32 bit wide stack params together
                    on non-debug, either its special and a 8 byte, or its
                    not special and a 4 byte
                */
		case T_POINTER:
		case T_STRUCTURE:
        case T_POINTERPOINTER:
        case T_CODE:
		case T_NUMBER:
        case T_INTEGER:
		case T_CHAR:
		case T_NUMCHAR:
		case T_FLOAT:
#else
                default:
#endif
			p.pParam = param->p;
#ifdef WIN32_API_DEBUG
            if(param->t+1 == T_POINTER)
			printf("(XS)Win32::API::Call: parameter %d (P) is 0x%X \"%s\"\n", i, param->l, param->p);
            else if(param->t+1 == T_FLOAT)
			printf("(XS)Win32::API::Call: parameter %d (F) is %f\n", i, param->f);
            else
            printf("(XS)Win32::API::Call: parameter %d (N) is %ld\n", i, param->l);
#endif
#if (defined(_MSC_VER) || defined(BORLANDC))
			__asm {
                                push dword ptr [p];
			};
#elif (defined(__GNUC__))
        p.pParam = param->p;
	/* probably uglier than necessary, but works */
	asm ("pushl %0":: "g" (((unsigned int*)&p)[0]));
	/* { 
	  int idc;
	  printf ("dParam = ");
	  for (idc = 0; idc < sizeof(dParam); idc++) {
		printf(" %2.2x",((unsigned char*)&dParam)[idc]);
	  } 
	  printf("   %f\n", dParam);
	} */
#endif /* VC VS GCC */

			break;

#ifdef WIN32_API_DEBUG
        default:
            Perl_croak_nocontext("Win32::API::Call Call_asm unknown in type %u @%u", param->t + 1, i);
            break;
#endif
		}
        i--;
	}

	/* #### NOW CALL THE FUNCTION #### */
	//todo, copy retval->t to a c auto, do switch on test c auto, switch might optimize
        //to being after the call instruction
    {
    unsigned char t = control->out;
    switch(t WIN32_API_DEBUGM( & ~T_FLAG_UNSIGNED) ) { //unsign has no special treatment here
    //group all EAX/EDX readers together, garbage high bytes will be tossed in Call()
#ifdef WIN32_API_DEBUG
/* do the type match only in debug mode, otherwise everything is a EAX/EDX unless
   otherwise tested, see way down for the debug mode default: label */
    case T_NUMBER:
    case T_SHORT:
    case T_CHAR:
    case T_NUMCHAR:
    case T_INTEGER:
    case T_VOID:
    case T_POINTER:
    case T_QUAD:
        switch(t & ~T_FLAG_UNSIGNED){
            case T_NUMBER:
            case T_SHORT:
            case T_CHAR:
            case T_NUMCHAR:
            printf("(XS)Win32::API::Call: Calling ApiFunctionNumber()\n");
            break;
            case T_INTEGER:
            printf("(XS)Win32::API::Call: Calling ApiFunctionInteger()\n");
            break;
            case T_VOID:
            printf("(XS)Win32::API::Call: Calling ApiFunctionVoid() (tout=%d)\n", t);
            break;
            case T_POINTER:
            printf("(XS)Win32::API::Call: Calling ApiFunctionPointer()\n");
            break;
            case T_QUAD:
            printf("(XS)Win32::API::Call: Calling ApiFunctionQuad()\n");
            break;
        }
#else
    default:
#endif  /* WIN32_API_DEBUG */
//always capture edx, even if garbage, both lines below are 64 bit
        STATIC_ASSERT(sizeof(retval->q) == 8);
        retval->q = ((ApiQuad *) control->ApiFunction)();
#ifdef WIN32_API_DEBUG
        switch(t & ~T_FLAG_UNSIGNED){
            case T_SHORT:
            printf("(XS)Win32::API::Call: ApiFunctionInteger (short) returned %hd\n", retval->s);
            break;
            case T_CHAR:
            case T_NUMCHAR:
            printf("(XS)Win32::API::Call: ApiFunctionInteger (char) returned %d\n", retval->c);
            break;
            case T_NUMBER: /* ptr always 32 */
            case T_INTEGER:
            printf("(XS)Win32::API::Call: ApiFunctionInteger returned %d\n", (int)retval->l);
            break;
            case T_VOID:
            printf("(XS)Win32::API::Call: ApiFunctionVoid returned");
            break;
            case T_POINTER:
            printf("(XS)Win32::API::Call: ApiFunctionPointer returned 0x%x '%s'\n", retval->p, retval->p);
            break;
            case T_QUAD:
            printf("(XS)Win32::API::Call: ApiFunctionQuad returned %I64d\n", retval->q);
            break;
        }
#endif  //WIN32_API_DEBUG
        break;
    case T_FLOAT:
#ifdef WIN32_API_DEBUG
    	printf("(XS)Win32::API::Call: Calling ApiFunctionFloat()\n");
#endif
        retval->f = ((ApiFloat *) control->ApiFunction)();
#ifdef WIN32_API_DEBUG
        printf("(XS)Win32::API::Call: ApiFunctionFloat returned %f\n", retval->f);
#endif
        break;
    case T_DOUBLE:
#ifdef WIN32_API_DEBUG
    	printf("(XS)Win32::API::Call: Calling ApiFunctionDouble()\n");
#endif
#if (defined(_MSC_VER) || defined(__BORLANDC__))
		/*
			_asm {
			call    dword ptr [ApiFunctionDouble]
			fstp    qword ptr [dReturn]
		}
		*/
	    retval->d = ((ApiDouble *) control->ApiFunction)();
#elif (defined(__GNUC__))
	    retval->d = ((ApiDouble *) control->ApiFunction)();
            /*
              asm ("call *%0"::"g" (ApiFunctionDouble));
              asm ("fstpl %st(0)");
              asm ("movl %0,(%esp)");
            */
#endif
#ifdef WIN32_API_DEBUG //use default: only in debug mode for perf
       printf("(XS)Win32::API::Call: ApiFunctionDouble returned %f\n", retval->d);
        break;
    default:
        croak("Win32::API::Call: unknown %s type", "out");
        break;
#endif
    }
    }
//#ifdef _MSC_VER
//__asm {
//    cmp esi, esp
//    call _RTC_CheckEsp
//}
//#endif

    // cleanup stack for _cdecl type functions.
//TODO investigate removing me on VC (possible), and GCC (WIP)
{
    unsigned int stack_unwind = (control->whole_bf >> 6) & 0x3FFFC;
#if (defined(_MSC_VER) || defined(__BORLANDC__))
    _asm {
        add esp, stack_unwind
    };
#elif (defined(__GNUC__))
    asm ( 
        "movl %0, %%eax\n" 
        "addl %%eax, %%esp\n" 

        : /* no output */ 
        : "g" (stack_unwind) /* input */
        : "%eax" /* modified registers */ 
    );
    {
        register void * raw_esp asm("esp");
        void * new_esp = raw_esp;
        if(raw_esp != orig_esp) {
            if(IsDebuggerPresent()) DebugBreak();
            else Perl_croak_nocontext(bad_esp_msg, orig_esp, raw_esp);
        }
    }
#endif
}
}

#ifdef __GNUC__
#  if GCC_VERSION >= 40400
#    pragma GCC pop_options
#  endif
#endif

#else /* Call_asm is in a different compliand */

#ifdef __cplusplus
extern "C"
#else
extern
#endif
void __fastcall Call_asm(const APIPARAM * param /*in caller, this a * to after the last
                                      initialized struct, on entry, param is
                                      always pointing to uninit memory*/,
              const APIPARAM * const params_start,
              const APICONTROL * const control,
              APIPARAM_U * const retval);

#endif /* #if 0*/
