/* Mostly WIDE/UTF16/UNICODE_STRING related helpers
   and a little bit of ppport.h style stuff. */

/* SvGROW() blindly reaches into SvLEN() and SEGVs even for SVt_IV/SVt_NULL.
   Don't expand SvGROW(), fut-proof incase "#ifdef PERL_ANY_COW #def SvGROW(s,l)
  (SvIsCOW(s)||SvLEN(s)<(l)?" macro changes. */
#define SafeSvGROW(sv,_l) (SvTYPE(sv) >= SVt_PV \
    ? SvGROW((sv),(_l)) : (sv_grow((sv),(_l))))
#define SafeSvGROWThink1ST(sv,_l) \
    (SvTYPE(sv) >= SVt_PV && !SvTHINKFIRST(sv) && !SvOOK(sv) \
    ? SvGROW((sv),(_l)) \
    : (sv_grow((sv),(_l))))

/* PERL_CORE only <= 5.41.6, maybe PERL_CORE forever, but its handy. */
#ifndef STRLENs
#  define STRLENs(s) (sizeof("" s "")-1)
#endif

#ifndef ASSERT_IS_LITERAL
#  define ASSERT_IS_LITERAL(s) ("" s "")
#endif


/* #undef MAX */ /* catch CPP header problems */
#define MAX(a,b) ((a) > (b) ? (a) : (b))

#define CBP STMT_START { __debugbreak(); } STMT_END

#ifdef _MSC_VER
#  if defined (_WIN64) && defined (_M_IA64)
#  pragma section(".base", long, read)
__declspec(allocate(".base"))
EXTERN_C const IMAGE_DOS_HEADER __ImageBase;
#  else
EXTERN_C const IMAGE_DOS_HEADER __ImageBase;
#  endif
#  define ImageBase_XSBULK88 __ImageBase
#else
  /*mgw64 gcc 8.3.0 has __ImageBase, mgw 3.4.5 does not */
EXTERN_C const IMAGE_DOS_HEADER _image_base__;
#  define ImageBase_XSBULK88 _image_base__
#endif

STATIC const char * S_ImpFunc2StrK32Dll(const void ** const imp_vp);

/* Disabled. Previous versions with less efficient machine code. */
#if 0
static Size_t K32Abs_OriginalFirstThunk = PTR2nat(&ImageBase_XSBULK88);
static Size_t K32Abs_FirstThunk = PTR2nat(&ImageBase_XSBULK88);
#endif

static const Size_t ImageBase_XSBULK88_plus2 = PTR2nat(&ImageBase_XSBULK88) + 2;
static Size_t K32Abs_DeltaFirstToOrigThunk = PTR2nat(NULL);

/* No point using struct MY_CXT, since there is no way for the Perl interp to ithread/psuedo-fork/psuedo-process/virtualize AreFileApisANSI(), SetFileApisToOEM(), and SetFileApisToANSI() from being process-wide/address-space-wide C global vars inside kernel32.dll, to be per OS thread/per CPU core, "TLS" vars compatible with Perl 5. */

static UINT gBKXSTK_sys_filepath_cp = CP_ACP;

#ifndef av_store_simple
PERL_STATIC_INLINE SV**
Perl_av_store_simple(pTHX_ AV *av, SSize_t key, SV *val)
{
    SV** ary;

    assert(SvTYPE(av) == SVt_PVAV);
    assert(!SvMAGICAL(av));
    assert(!SvREADONLY(av));
    assert(AvREAL(av));
    assert(key > -1);

    ary = AvARRAY(av);

    if (AvFILLp(av) < key) {
        if (key > AvMAX(av)) {
            av_extend(av,key);
            ary = AvARRAY(av);
        }
        AvFILLp(av) = key;
    } else
        SvREFCNT_dec(ary[key]);

    ary[key] = val;
    return &ary[key];
}
#  define av_store_simple(a,b,c) Perl_av_store_simple(aTHX_ a,b,c)
#endif

#ifndef av_new_alloc
PERL_STATIC_INLINE AV *
Perl_av_new_alloc(pTHX_ SSize_t size, bool zeroflag)
{
    AV * const av = newAV();
    SV** ary;
    assert(size > 0);

    Newx(ary, size, SV*); /* Newx performs the memwrap check */
    AvALLOC(av) = ary;
    AvARRAY(av) = ary;
    AvMAX(av) = size - 1;

    if (zeroflag)
        Zero(ary, size, SV*);

    return av;
}
#  define av_new_alloc(a,b) Perl_av_new_alloc(aTHX_ a,b)
#endif

#ifndef newAV_alloc_x
#  define newAV_alloc_x(size)  av_new_alloc(size,0)
#endif

#ifndef newAV_alloc_xz
#  define newAV_alloc_xz(size) av_new_alloc(size,1)
#endif

#ifndef av_fetch_simple
PERL_STATIC_INLINE SV**
Perl_av_fetch_simple(pTHX_ AV *av, SSize_t key, I32 lval)
{
    assert(SvTYPE(av) == SVt_PVAV);
    assert(!SvMAGICAL(av));
    assert(!SvREADONLY(av));
    assert(AvREAL(av));
    assert(key > -1);

    if ( (key > AvFILLp(av)) || !AvARRAY(av)[key]) {
        return lval ? av_store_simple(av,key,newSV_type(SVt_NULL)) : NULL;
    } else {
        return &AvARRAY(av)[key];
    }
}
#  define av_fetch_simple(a,b,c) Perl_av_fetch_simple(aTHX_ a,b,c)
#endif


#ifndef sv_setrv_noinc
#  ifndef prepare_SV_for_RV
#    define prepare_SV_for_RV(sv)						\
    STMT_START {							\
                    if (SvTYPE(sv) < SVt_PV && SvTYPE(sv) != SVt_IV)	\
                        sv_upgrade(sv, SVt_IV);				\
                    else if (SvTYPE(sv) >= SVt_PV) {			\
                        SvPV_free(sv);					\
                        SvLEN_set(sv, 0);				\
                        SvCUR_set(sv, 0);				\
                    }							\
                 } STMT_END
#  endif
STATIC void
S_Perl_sv_setrv_noinc(pTHX_ SV *const sv, SV *const ref)
{
    SV_CHECK_THINKFIRST_COW_DROP(sv);
    prepare_SV_for_RV(sv);

    SvOK_off(sv);
    SvRV_set(sv, ref);
    SvROK_on(sv);
}
#  define sv_setrv_noinc(a,b) S_Perl_sv_setrv_noinc(aTHX_ a,b)
#endif

#ifndef newSV_type_mortal
PERL_STATIC_INLINE SV *
S_Perl_newSV_type_mortal(pTHX_ const svtype type)
{
    SV *sv = newSV_type(type);
    SSize_t ix = ++PL_tmps_ix;
    if (UNLIKELY(ix >= PL_tmps_max))
        ix = Perl_tmps_grow_p(aTHX_ ix);
    PL_tmps_stack[ix] = (sv);
    SvTEMP_on(sv);
    return sv;
}
#  define newSV_type_mortal(_type) S_Perl_newSV_type_mortal(aTHX_ _type)
#endif

/* Croak with XSUB's name prefixed, and any suffix string, taken from
   croak_xs_usage */
STATIC void
S_croak_sub(const CV *const cv, const char *const params)
{
/* This executes so rarely, avoid overhead of passing my_perl in callers. */
    dTHX;
    const GV *const gv = CvGV(cv);

    if (gv) {
        const char *const gvname = GvNAME(gv);
        const HV *const stash = GvSTASH(gv);
        const char *const hvname = stash ? HvNAME(stash) : NULL;

        if (hvname)
          Perl_croak_nocontext("%s::%s: %s", hvname, gvname, params);
        else
          Perl_croak_nocontext("%s: %s", gvname, params);
    } else {
        /* Pants. I don't think that it should be possible to get here. */
        Perl_croak_nocontext("CODE(0x%" UVxf "): %s", PTR2UV(cv), params);
    }
}


/* Croak with XSUB's name prefixed, taken from croak_xs_usage, this func
   has less overhead (read GLR again) in each caller vs the next func. */
#define croak_sub_glr(_cv, _syscallpv) S_croak_sub_glr((_cv), (_syscallpv))
STATIC void
S_croak_sub_glr(const CV *const cv, const char *const syscallpv)
{
    char buf [128+sizeof("%s GetLastError=%u (0x%x)")+12+9];
    const DWORD err = GetLastError();
    my_snprintf((char *)buf, sizeof(buf)-1, "%s GetLastError=%u (0x%x)",
                syscallpv, err, err);
    S_croak_sub(cv, (const char *)buf);
}

/* Croak with XSUB's name prefixed, taken from croak_xs_usage */
#define croak_sub_glrex(_cv, _syscallpv, _e) S_croak_sub_glrex((_cv), (_syscallpv), (_e))
STATIC void
S_croak_sub_exglr(const CV *const cv, const char *const syscallpv, DWORD err)
{
    char buf [128+sizeof("%s GetLastError=%u (0x%x)")+12+9];
    my_snprintf((char *)buf, sizeof(buf)-1, "%s GetLastError=%u (0x%x)",
                syscallpv, err, err);
    S_croak_sub(cv, (const char *)buf);
}

STATIC void
S_croak_sub_glr_fn(CV* cv, const char * fn) {
    const DWORD e = GetLastError();
    char buf [128+MAX(STRLENs("GPA e=%x ord=%d"), STRLENs("GPA e=%x fn=%s"))+9+9+1];
    const char * fmt = PTR2nat(fn) <= 0xFFFF ? "GPA e=%x ord=%d" : "GPA e=%x fn=%s";
    my_snprintf((char *)buf, sizeof(buf)-1, fmt, e, fn);
    S_croak_sub(cv, buf);
}

STATIC void
S_croak_sub_glr_k32_imp_str(const CV *const cv, const void ** const imp_vp) {
    const char * const p = S_ImpFunc2StrK32Dll(imp_vp);
    S_croak_sub_glr(cv, p);
}

#ifdef _WIN64
#  define S_croak_sub_glr_k32(_cv, _tok) S_croak_sub_glr_k32_imp_str(_cv, (const void **)PTR2nat((&__imp_##_tok)))
#else
#  define S_croak_sub_glr_k32(_cv, _tok) S_croak_sub_glr_k32_imp_str(_cv, (const void **)PTR2nat((&_imp__##_tok)))
#endif


/* usage: printf("X %s X", K32FN2STR(GetProcAddress));
   output: "X GetProcAddress X" or "X _GetProcAddress X" or "X GetProcAddress@8 X"

   Converts a C function/symbol/token/indentifier/32-bit-RVA from THIS DLL's
   PE import table, to a const char * pointer, which points to the
   null-terminated ASCII string name inside this particular DLL's PE import
   table, that represents that C function/symbol/token/indentifier/32-bit-RVA
   for PE/DLL Loader linking purposes. Benefit: don't have 2 unique copies
   inside this XS .dll file of null-term ASCII strings:

   "GetModuleFileNameW", "VirtualProtect", "FreeLibrary", "CreateFileW",
   "WideCharToMultiByte", "MultiByteToWideChar", etc, and so forth.

   1st copy is a C lang level "cstr" literal that gets de-duped by the C linker
   against other src code/-O1/-O2 copies and references to the same
   C lang level "cstr" literal.

   2nd copy is from kernel32.lib or msvcrt.lib/ucrtbase.lib, which becomes
   part of this DLL's import table.

   The MSVC and Mingw C linkers are too dumb to realize the C string aka
   "const stored variable length byte array" from kernel32.lib/.a or
   msvcrt.lib/.a, and the double quoted C src code literal string,
   Both have IDENTICAL length and byte contents!!!
   Both have C const/HW RO global storage!!!
   Both can be de-duped at C link time!!! */

#undef APPRVA2ABS
#define APPRVA2ABS(x) ((DWORD_PTR)dosHeader + (DWORD_PTR)(x))

#if 0 /* Disabled. Previous versions with less efficient machine code. */

STATIC const char *
S_ImpFunc2StrK32Dll1(const void ** const imp_vp) {
    const PIMAGE_DOS_HEADER dosHeader = (PIMAGE_DOS_HEADER)&(ImageBase_XSBULK88);
    /* PIMAGE_IMPORT_DESCRIPTOR importDescriptor = (PIMAGE_IMPORT_DESCRIPTOR)APPRVA2ABS(pDataDirImportRVA); */
    const PIMAGE_IMPORT_DESCRIPTOR importDescriptor =
        (const PIMAGE_IMPORT_DESCRIPTOR) &__IMPORT_DESCRIPTOR_KERNEL32;
    const PIMAGE_THUNK_DATA OriginalFirstThunk =
        (const PIMAGE_THUNK_DATA) APPRVA2ABS(importDescriptor->OriginalFirstThunk);
    const void ** const FirstThunk = (const void**) APPRVA2ABS(importDescriptor->FirstThunk);
    /* All MSVCs, all versions ever, VC6 (tested) through VC 2022 (tested)
       have a bad optimizer that emits machine code that looks like:
            ptr -= &ImageBase; ptr >>= 3; ptr <<= 3; str = arr_of_char_ptrs+ptr;
    const U32 idx = imp_vp - FirstThunk;
    const PIMAGE_THUNK_DATA OriginalFirstThunk_Slot = OriginalFirstThunk + idx; */
    const PIMAGE_THUNK_DATA OriginalFirstThunk_Slot = (PIMAGE_THUNK_DATA)
        (PTR2nat(OriginalFirstThunk) + (PTR2nat(imp_vp)-PTR2nat(FirstThunk)));
    const char * fName = (const char *)(PTR2nat(dosHeader) + PTR2nat(OriginalFirstThunk_Slot->u1.Function));
    fName += 2; /* skip field U16 Hint */
    return fName;
}

STATIC const char *
S_ImpFunc2StrK32Dll2(const void ** const imp_vp) {
    const PIMAGE_THUNK_DATA OriginalFirstThunk_Slot = (PIMAGE_THUNK_DATA)(
        PTR2nat(K32Abs_OriginalFirstThunk)
        + (PTR2nat(imp_vp)-PTR2nat(K32Abs_FirstThunk))
    );
    const char * fName = (const char *)(
        ImageBase_XSBULK88_plus2
        + PTR2nat(OriginalFirstThunk_Slot->u1.Function)
    );
    return fName;
}

#endif /* Disabled. Previous versions with less efficient machine code. */

STATIC const char *
S_ImpFunc2StrK32Dll(const void ** const imp_vp) {
    const PIMAGE_THUNK_DATA OriginalFirstThunk_Slot = (PIMAGE_THUNK_DATA)(
        PTR2nat(imp_vp)
        - PTR2nat(K32Abs_DeltaFirstToOrigThunk)
    );
    const char * fName = (const char *)(
        ImageBase_XSBULK88_plus2
        + PTR2nat(OriginalFirstThunk_Slot->u1.Function)
    );
    return fName;
}
#undef APPRVA2ABS

/* Macro expands to    S_ImpFunc2StrK32Dll(&__imp_GetProcAddress)

   __imp_GetProcAddress   is basically writing lval/rval    DLLImportFnPtrArr[1234]
   DLLImportFnPtrArr    is decl as    extern const void * DLLImportFnPtrArr[4321];
   and &__imp_GetProcAddress is of type void ** and points to somewhere inside
   the DLLImportFnPtrArr array.

   NOTE!!! C grammer token/C fn ptr "GetProcAddress" CAN NOT be 100% reliably
   converted to a "const char *" and CAN NOT be 100% guarenteed to be found
   inside array DLLImportFnPtrArr by doing a linear search.  MSVC/GCC using
   -Od/-O0/Edit & Continue/hot in-use recompile then relink then reload
   a .exe/.dll inside a single stepping C dbg (MSVC or GDB), will create
   very tiny jmp-stubs/jmp-thunk C functions/function pointers that aren't the
   ptr/address/integer that will be found calling K32's GetProcAddress(),
   or found inside THIS DLL's import table void * array.
   
   Using "&__imp_GetProcAddress" instead of
      while(; *needle; needle++) {
        if(arg1_pfn_GetProcAddress == *needle)
          return (const char *) TO_ABS_PTR(DllImpTableAsciiNames[TO_REL_OFFSET(needle)]);
      }
   removes the O(n) search and compare loop, and removes risk of
   the fn ptr inside var arg1_pfn_GetProcAddress being un-findable b/c
   arg1_pfn_GetProcAddress is holding a fn ptr to a linker created jmp-stub.
 */


#ifdef _WIN64
#  define K32FN2STR(_tok) S_ImpFunc2StrK32Dll((const void **)&__imp_##_tok)
#else
#  define K32FN2STR(_tok) S_ImpFunc2StrK32Dll((const void **)&_imp__##_tok)
#endif

/* file paths only, uses API.dll's manually updated AreFileApisANSI global var */
static SSize_t
sv_to_wstr_cstk(pTHX_ const CV *const cv, SV *sv, WCHAR *wstr, int wlen)
{
    DWORD e;
    char *str;
    UINT cp;
    int wlen_guess;
    STRLEN len = SvCUR(sv);
    /* if(len > INT_MAX)
        croak_xs_usage(cv, "len(str)<=" STRINGIFY(INT_MAX)); */
    if(len > 0xFFFE) {
        SetLastError(ERROR_FILENAME_EXCED_RANGE);
        goto croak_err;
    }
    wlen_guess = ((int)len) + 1;
    if( wlen_guess > wlen) {
      return -((SSize_t)wlen_guess);
    }
    else if (len == 0) { /* output WIDE string is obvious */
        wstr[0] = 0;
        return 1;
    }
    str = SvPVX(sv);
    cp = SvUTF8(sv) ? CP_UTF8 : gBKXSTK_sys_filepath_cp; /* typ CP_ACP */
    wlen = MultiByteToWideChar(cp, 0, str, (int)(len+1), wstr, wlen);
    if(wlen == 0) {
        e = GetLastError();
        if(e == ERROR_INSUFFICIENT_BUFFER) { /* not BMP ??? */
            wlen = MultiByteToWideChar(cp, 0, str, (int)(len+1), NULL, 0);
            if(wlen == 0) /* probably illegal code point in some code page */
                goto croak_err;
            /* null or paranoia, are inputs from supposed to have a
               narrow nul byte that comes out as output*/
            wlen++;
            return -wlen;
        }
        else /* probably illegal code point in some code page */
            goto croak_err;
    }
    return wlen;

    croak_err:
    S_croak_sub_glr_k32(cv, MultiByteToWideChar);
    return 0;
}

/* Convert wide character string to mortal SV.  Use UTF8 encoding
 * if the string cannot be represented in the ANSI/OEM filepath system
 * codepage. ANSI/OEM change detection triggered by user calling an XSUB. Not
 * automatic polling.
 * Probably not for OLE. Users switching OEM FP CP is very rare. Won't affect
 * most people.
 * If wlen isn't -1 (calculate length), wlen must include the null wchar
 * in its count of wchars, and null wchar must be last wchar.
 * This function has the typical WinOS 65KB limit, and we only uses C stack
 * mem for speed, and therefore must have some hard coded limit
 * Arg "INT_PTR wlenparam" must have a PP visible 2 byte WIDE NULL at the end.
 * Perl's hidden 1 byte C ASCII NULL isn't good enough.
 */
STATIC SV *
S_sv_setwstr(pTHX_ const CV *const cv, SV * sv, WCHAR *wstr, INT_PTR wlenparam) {
    char * dest;
    BOOL use_default = FALSE;
    BOOL * use_default_ptr = &use_default;
    UINT CodePage;
    DWORD dwFlags;
    int len;
    /* note 0xFFFFFFFFFFFFFFFF and 0xFFFFFFFF truncate to the same here on x64*/
    int wlen;// = (int) wlenparam;
    WCHAR * tempwstr = NULL;

#ifdef _WIN64     /* WCTMB only takes 32 bits ints*/
    if(wlenparam > (INT_PTR) INT_MAX && wlenparam != 0xFFFFFFFF)
      //croak("(XS) " MODNAME "::w32sv_setwstr panic: %s", "string overflow\n");
        S_croak_sub_exglr(cv, "sv_setwstr", ERROR_BUFFER_OVERFLOW);
#endif
    wlen = (int) wlenparam;

    /* can't pass -1 to WCTMB, that triggers length counting but WCTMB is slow */
    if(wlen == -1)
        wlen = (int)wcslen(wstr)+1; /* wrap around chk done later*/

    /*a Win32 API might claiming to create null terminated, length counted, string
    but infact is creating non terminated, length counted, strings, catch it*/
    else {
      wlen += 1;
      if(wstr[wlen-1] != L'\0')
      //croak("(XS) " MODNAME "sv_setwstr panic: %s",
      //      "wide string is not null terminated\n");
        S_croak_sub_exglr(cv, "sv_setwstr", ERROR_INVALID_USER_BUFFER);
    }

    if(
/* SvPVX in head, not ANY/body, added in 5.9.3, dont crash */
#if (PERL_VERSION_LE(5, 9, 2))
        SvTYPE(sv) >= SVt_PV &&
#endif
        /* Todo Change to alloca vs mortal */
       ((WCHAR *)SvPVX(sv)) == wstr) {//WCTMB bufs cant overlap
        SV * widecopysv = sv_2mortal(newSV(wlen*sizeof(WCHAR)));
        tempwstr = ((WCHAR *)SvPVX(widecopysv));
        Move(wstr, tempwstr, wlen, sizeof(WCHAR));
    }

    if(SvOOK(sv)) {
        SvCUR_set(sv, 0); /* skip memcpy relocation of old buffer */
        sv_backoff(sv); /* small chance to recover bytes w/o libc trip */
    } /* small "WIDE/2 ASCII" guess, its malloc mem so be conservative */
    dest = SafeSvGROWThink1ST(sv, (STRLEN)wlen);
    CodePage = gBKXSTK_sys_filepath_cp;
    dwFlags = WC_NO_BEST_FIT_CHARS;
    len = WideCharToMultiByte(CodePage, dwFlags, wstr, wlen, dest, wlen, NULL, use_default_ptr);
    if(len)
        goto chk_sub_ascii_chars;

    if(GetLastError() != ERROR_INSUFFICIENT_BUFFER)
        goto set_undef;

    retry: /* try harder to stay in ASCII mode (perl utf8 strings slower than
    perl byte). Do a length-only pass in ASCII with longer SVPV buf before
    trying utf8. WCTMB doesn't return "size needed" integer after an
    overflow/cutoff event, if b4 you passed in a a valid byte Ptr to fill.
    WCTMB only rets "size needed" if you pass NULL ptr for output. */
    len = WideCharToMultiByte(CodePage, dwFlags, wstr, wlen, NULL, 0, NULL, NULL);
    dest = SafeSvGROW(sv, (STRLEN)len); /* SvGROW() segv if SVt_NULL/bodyless */
    len = WideCharToMultiByte(CodePage, dwFlags, wstr, wlen, dest, len, NULL, use_default_ptr);

    chk_sub_ascii_chars:
    if (use_default) {
        SvUTF8_on(sv);
        use_default = FALSE;
        use_default_ptr = NULL;
        /*this branch will never be taken again*/
        CodePage = CP_UTF8;
        dwFlags = 0;
        goto retry;
    }
    /* Shouldn't really ever fail since we ask for the required length first, but who knows... */
    if (len) {
        SvPOK_on(sv);
        SvCUR_set(sv, len-1);
    }
    else {
        set_undef:
        SvOK_off(sv);
        SvCUR_set(sv,0);
    }
    return sv;
}

/* file paths only, uses API.dll's manually updated AreFileApisANSI global var */
static SSize_t
pv_to_wstr_cstk(pTHX_ const CV *const cv, const char * str, int len, WCHAR *wstr, int wlen)
{
    DWORD e;
    UINT cp;
    int wlen_guess;
    if(len > 0xFFFE) {
        SetLastError(ERROR_FILENAME_EXCED_RANGE);
        goto croak_err;
    }
    wlen_guess = ((int)len) + 1;
    if( wlen_guess > wlen) {
      return -((SSize_t)wlen_guess);
    }
    else if (len == 0) { /* output WIDE string is obvious */
        wstr[0] = 0;
        return 1;
    }
    cp = gBKXSTK_sys_filepath_cp;
    wlen = MultiByteToWideChar(cp, 0, str, (int)(len+1), wstr, wlen);
    if(wlen == 0) {
        e = GetLastError();
        if(e == ERROR_INSUFFICIENT_BUFFER) { /* not BMP ??? */
            cp = gBKXSTK_sys_filepath_cp;
            wlen = MultiByteToWideChar(cp, 0, str, (int)(len+1), NULL, 0);
            if(wlen == 0) /* probably illegal code point in some code page */
                goto croak_err;
            /* null or paranoia, are inputs from supposed to have a
               narrow nul byte that comes out as output*/
            wlen++;
            return -wlen;
        }
        else /* probably illegal code point in some code page */
            goto croak_err;
    }
    return wlen;

    croak_err:
    S_croak_sub_glr_k32(cv, MultiByteToWideChar);
    return 0;
}

/* EXAMPLE
    WCHAR warr[MAX_PATH];
    WCHAR * wstr = warr;
    int wlen = MAX_PATH;
    while((wlen = (int)sv_to_wstr_cstk(aTHX_ cv, name, wstr, wlen)) < 0) {
        wlen = -wlen;
        wstr = (WCHAR*)alloca((wlen+4)*2);
    }
*/

static SSize_t
wstr_to_pv_cstk(pTHX_ const CV *const cv,  WCHAR *wstr, int wlen, char * str, int len)
{
    DWORD e;
    UINT cp;
    int len_guess;
    if(wlen > 0xFFFE) {
        SetLastError(ERROR_FILENAME_EXCED_RANGE);
        goto croak_err;
    }
    len_guess = ((int)wlen) + 1;
    if( len_guess > len) {
      return -((SSize_t)len_guess);
    }
    else if (len == 0) { /* output ANSI string is obvious */
        str[0] = 0;
        return 1;
    }
    cp = gBKXSTK_sys_filepath_cp;
    len = WideCharToMultiByte(cp, 0, wstr, wlen+1, str, len, NULL, NULL);
    if(len == 0) {
        e = GetLastError();
        if(e == ERROR_INSUFFICIENT_BUFFER) {
            cp = gBKXSTK_sys_filepath_cp;
            len = WideCharToMultiByte(cp, 0, wstr, wlen+1, NULL, 0, NULL, NULL);
            if(len == 0) /* probably illegal code point in some code page */
                goto croak_err;
            /* null or paranoia, are inputs from supposed to have a
               narrow nul byte that comes out as output*/
            len++;
            return -len;
        }
        else /* probably illegal code point in some code page */
            goto croak_err;
    }
    return len;

    croak_err:
    S_croak_sub_glr_k32(cv, WideCharToMultiByte);
    return 0;
}

XS_INTERNAL(BulkTools_XS_AreFileApisANSI); /* prototype to pass -Wmissing-prototypes */
XS_INTERNAL(BulkTools_XS_AreFileApisANSI)
{
    dVAR; dXSARGS;
    BOOL r;
    if (items != 0)
       croak_xs_usage(cv,  "");
    r = AreFileApisANSI();
    gBKXSTK_sys_filepath_cp = r ? CP_ACP : CP_OEMCP;
    PUSHs(boolSV(r)); /* 0 in, 1 out, no EXTEND() b/c its 1 out */
    PUTBACK;
    return;
}

#ifdef USE_ITHREADS
XS_INTERNAL(BulkTools_XS_CLONE_SKIP); /* prototype to pass -Wmissing-prototypes */
XS_INTERNAL(BulkTools_XS_CLONE_SKIP)
{
    dVAR; dXSARGS;
    XSRETURN_YES;
}
#endif

#ifdef CRT_BLOAT_RMV
/* get rid of CRT startup code on MSVC, it is bloat, this module uses 2
   libc functions, memcpy and swprintf, they dont need initialization */
#  ifdef _MSC_VER
BOOL WINAPI _DllMainCRTStartup(
    HINSTANCE hinstDLL,
    DWORD fdwReason,
    LPVOID lpReserved )
{
    BOOL ret;
    if (fdwReason == DLL_PROCESS_ATTACH) {
        ret = DisableThreadLibraryCalls(hinstDLL);
        if(!ret)
            return ret;
        ret = INIT_MAYBE_PROCESS_ATTACH();
        return ret;
    }
    return TRUE;
}
#  else
/* bc Mingw/GCC always has/links in a couple (useless) PE header TLSCallback 'es
   we must not call DisableThreadLibraryCalls(), bc DisableThreadLibraryCalls()
   will return FALSE (syscall has failed), if it is passed a HMODULE hinstDLL
   that has PE header TLSCallback functions. */
BOOL WINAPI DllMain(
    HINSTANCE hinstDLL,
    DWORD fdwReason,
    LPVOID lpReserved )
{
    if (fdwReason == DLL_PROCESS_ATTACH) {
        BOOL ret;
        ret = INIT_MAYBE_PROCESS_ATTACH();
        return ret;
    }
}
#  endif
#else
/* Don't override or replace the secret and huge default DllMain impl that
   MSVC/Mingw link into every .exe/.dll */
#  ifdef _MSC_VER
BOOL WINAPI DllMain(
    HINSTANCE hinstDLL,
    DWORD fdwReason,
    LPVOID lpReserved )
{
    BOOL ret;
    if (fdwReason == DLL_PROCESS_ATTACH) {
        ret = DisableThreadLibraryCalls(hinstDLL);
        if(!ret)
            return ret;
        ret = INIT_MAYBE_PROCESS_ATTACH();
        return ret;
    }
    return TRUE;
}
#  else
BOOL WINAPI DllMain(
    HINSTANCE hinstDLL,
    DWORD fdwReason,
    LPVOID lpReserved )
{
    if (fdwReason == DLL_PROCESS_ATTACH) {
        BOOL ret;
        ret = INIT_MAYBE_PROCESS_ATTACH();
        return ret;
    }
}
#  endif
#endif
