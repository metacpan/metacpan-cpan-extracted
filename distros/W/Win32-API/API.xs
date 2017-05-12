/*
    # Win32::API - Perl Win32 API Import Facility
    #
    # Author: Aldo Calpini <dada@perl.it>
    # Author: Daniel Dragan <bulk88@hotmail.com>
    # Maintainer: Cosimo Streppone <cosimo@cpan.org>
    #
    # $Id$
 */

#define  WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <memory.h>
#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define CROAK croak
//#include <emmintrin.h>
#include "API.h"

/*
 * some Perl macros for backward compatibility
 */
#ifdef NT_BUILD_NUMBER
#define boolSV(b) ((b) ? &sv_yes : &sv_no)
#endif

#ifndef PL_na
#	define PL_na na
#endif

#ifndef SvPV_nolen
#	define SvPV_nolen(sv) SvPV(sv, PL_na)
#endif

#ifndef call_pv
#	define call_pv(name, flags) perl_call_pv(name, flags)
#endif

#ifndef call_method
#	define call_method(name, flags) perl_call_method(name, flags)
#endif

#define MODNAME "Win32::API"

/*added because of http://www.cpantesters.org/cpan/report/fd483be1-6c0a-1014-9049-f37bd871b27e
  but the below isn't the problem to above report, memset func ptr being
  NULL in the DLL is */
#if defined(_MSC_VER) && defined(__GNUC__)
#  error A compiler can be either _MSC_VER or __GNUC__, not both
#endif

/*get rid of CRT startup code on MSVC, we use exactly 3 CRT functions
memcpy, memmov, and wcslen, neither require any specific initialization other than
loading the CRT DLL (SSE probing on modern CRTs is done when CRT DLL is loaded
not when a random DLL subscribes to the the CRT), Mingw has more startup code
than MSVC does, so I (bulk88) will leave Mingw's CRT startup code in*/
#ifdef _MSC_VER
BOOL WINAPI _DllMainCRTStartup(
    HINSTANCE hinstDLL,
    DWORD fdwReason,
    LPVOID lpReserved )
{
    switch( fdwReason ) 
    { 
        case DLL_PROCESS_ATTACH:
            if(!DisableThreadLibraryCalls(hinstDLL)) return FALSE;
            break;
        case DLL_PROCESS_DETACH:
            break;
    }
    return TRUE;
}
#endif

#pragma pack(push)
#pragma pack(push, 1)
#ifdef _MSC_VER
extern __declspec(selectany) /*enable comdat folding for this symbol in msvc*/
#endif
PORTALIGN(1) const char bad_esp_msg [] = "Win32::API a function was called with the wrong prototype "
"and caused a C stack inconsistency EBP=%p ESP=%p" ;
#pragma pack(pop)
#pragma pack(pop)

#pragma pack(push)
#pragma pack(push, 1)
#ifdef _MSC_VER
extern __declspec(selectany) /*enable comdat folding for this symbol in msvc*/
#endif
PORTALIGN(1) const struct {
    char Unpack [sizeof("Win32::API::Type::Unpack")];
    char Pack [sizeof("Win32::API::Type::Pack")];
    char ck_type [sizeof("Win32::API::Struct::ck_type")];
} Param3FuncNames = {
    "Win32::API::Type::Unpack",
    "Win32::API::Type::Pack",
    "Win32::API::Struct::ck_type"
};
#pragma pack(pop)
#pragma pack(pop)

#define PARAM3_UNPACK ((int)((char*)(&Param3FuncNames.Unpack) - (char*)&Param3FuncNames))
#define PARAM3_PACK ((int)((char*)(&Param3FuncNames.Pack) - (char*)&Param3FuncNames))
#define PARAM3_CK_TYPE ((int)((char*)(&Param3FuncNames.ck_type) - (char*)&Param3FuncNames))
STATIC void pointerCall3Param(pTHX_ SV * sv1, SV * sv2, SV * sv3, int func_offset) {
    //for Type::Un/Pack obj, type, param, for ::Struct::ck_type param, proto, param_num
	dSP;
	W32APUSHMARK(SP);
    STATIC_ASSERT(CALL_PL_ST_EXTEND >= 3); //EXTEND replacement
    PUSHs(sv1);
    PUSHs(sv2);
	PUSHs(sv3);
	PUTBACK;
	call_pv((char*)&Param3FuncNames+func_offset, G_VOID|G_DISCARD);
}

STATIC SV * getTarg(pTHX) {
    dXSTARG;
    PREP_SV_SET(TARG);
    SvOK_off(TARG);
    return TARG;
}

/* Convert wide character string to mortal SV.  Use UTF8 encoding
 * if the string cannot be represented in the system codepage.
 * If wlen isn't -1 (calculate length), wlen must include the null wchar
 * in its count of wchars, and null wchar must be last wchar
 */
STATIC void w32sv_setwstr(pTHX_ SV * sv, WCHAR *wstr, INT_PTR wlenparam) {
    char * dest;
    BOOL use_default = FALSE;
    BOOL * use_default_ptr = &use_default;    
    UINT CodePage;
    DWORD dwFlags;
    int len;
    /* note 0xFFFFFFFFFFFFFFFF and 0xFFFFFFFF truncate to the same here on x64*/
    int wlen = (int) wlenparam; 
    WCHAR * tempwstr = NULL;
    
    /*can't pass -1 to WCTMB because of sv pv to wstr comparison and copy */
    if(wlen == -1) {
        wlen = (int)wcslen(wstr)+1;
    }
    /*a Win32 API might claiming to create null terminated, length counted, string
    but infact is creating non terminated, length counted, strings, catch it*/
    if(wstr[wlen-1] != L'\0') croak("(XS) " MODNAME "::w32sv_setwstr panic: %s", "wide string is not null terminated\n");
#ifdef _WIN64     /* WCTMB only takes 32 bits ints*/
    if(wlenparam > (INT_PTR) INT_MAX && wlenparam != 0xFFFFFFFF) croak("(XS) " MODNAME "::w32sv_setwstr panic: %s", "string overflow\n");
#endif
    if(
/* SvPVX in head, not ANY/body, added in 5.9.3, dont crash */
#if (PERL_VERSION_LE(5, 9, 2))
        SvTYPE(sv) >= SVt_PV &&
#endif
       ((WCHAR *)SvPVX(sv)) == wstr) {//WCTMB bufs cant overlap
        //dont trip MEM_WRAP_CHECK macro that is a pointless runtime assert
        Newx(*(char**)&tempwstr, (wlen*sizeof(WCHAR)), char);
        wstr = memcpy(tempwstr, wstr, wlen * sizeof(WCHAR));
    }
    CodePage = CP_ACP;
    dwFlags = WC_NO_BEST_FIT_CHARS;
    
    retry:
    len = WideCharToMultiByte(CodePage, dwFlags, wstr, wlen, NULL, 0, NULL, NULL);
    dest = sv_grow(sv, (STRLEN)len); /*access vio on macro*/
    len = WideCharToMultiByte(CodePage, dwFlags, wstr, wlen, dest, len, NULL, use_default_ptr);
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
        SvOK_off(sv);
    }
    if(tempwstr) Safefree(tempwstr);
}

#if defined(_M_AMD64) || defined(__x86_64)
#include "call_x86_64.h"
#elif defined(_M_IX86) || defined(__i386)
#include "call_i686.h"
#else
#error "Don't know what architecture I'm on."
#endif

#define MY_CXT_KEY "Win32::API_guts"
typedef struct {
    SV * sentinal;
    /* the *Key vars are all leaked SVs since MY_CXT struct's contents is never freeded
    bulk88 doesn't know where/when to call a dtor on these */
    /* obsolete, now in APICONTROL
    SV * controlKey;
    SV * intypesKey;
    SV * inKey;
    */
} my_cxt_t;

START_MY_CXT

/* returns cxt->sentinal */
static SV * initSharedKeys (pTHX_ my_cxt_t * cxt) {
    /* obsolete, now in APICONTROL
    cxt->controlKey = newSVpvs_share("control");
    cxt->intypesKey = newSVpvs_share("intypes");
    cxt->inKey = newSVpvs_share("in");
    */
    cxt->sentinal = get_sv("Win32::API::sentinal", 1); /* must be 1 b/c used in CLONE and BOOT */
    return cxt->sentinal;
}

/* declare as 5 member, not normal 8 to save image space*/
const static struct {
	int (*svt_get)(SV* sv, MAGIC* mg);
	int (*svt_set)(SV* sv, MAGIC* mg);
	U32 (*svt_len)(SV* sv, MAGIC* mg);
	int (*svt_clear)(SV* sv, MAGIC* mg);
	int (*svt_free)(SV* sv, MAGIC* mg);
} vtbl_API = {
	NULL, NULL, NULL, NULL, NULL
};

/* gets hidden magic SV from SV, returns NULL if not there, return is not refcnt++ed*/
STATIC SV * getMgSV(pTHX_ SV * sv) {
	MAGIC * mg;
	if(SvRMAGICAL(sv)) { /* implies SvTYPE  >= SVt_PVMG */
		mg = mg_findext(sv, PERL_MAGIC_ext, (const MGVTBL * const)&vtbl_API);
		if(mg) {
			return mg->mg_obj;
		}
		else return NULL;
	}
	else return NULL;
}

/* puts newsv, refcnt++ed (caller doesn't have to do it), in sv as hidden magic SV */
STATIC void setMgSV(pTHX_ SV * sv, SV * newsv) {
	MAGIC * mg;
	if(SvRMAGICAL(sv)) { /* implies SvTYPE  >= SVt_PVMG */
		mg = mg_findext(sv, PERL_MAGIC_ext, (const MGVTBL * const)&vtbl_API);
		if(mg) {
			SV * oldsv;
			SvREFCNT_inc_simple_void_NN(newsv);
			oldsv = mg->mg_obj;
			mg->mg_obj = newsv;
			SvREFCNT_dec(oldsv);
		} else {
			goto addmg;
		}
	}
	else {
		addmg:
		sv_magicext(sv,newsv,PERL_MAGIC_ext,(const MGVTBL * const)&vtbl_API,NULL,0);
	}
}

#include "Call.c"

MODULE = Win32::API   PACKAGE = Win32::API

PROTOTYPES: DISABLE

BOOT:
    newXS("Win32::API::Call", XS_Win32__API_Call, file);
{
    SV * sentinal;
    SENTINAL_STRUCT sentinal_struct;
    LARGE_INTEGER counter;
#ifdef WIN32_API_DEBUG
    const char * const SDumpStr = "(XS)Win32::API::boot: APIPARAM layout, member %s, SzOf %u, offset %u\n";
#endif
    STATIC_ASSERT(sizeof(sentinal_struct) == 12); //8+2+2
    STATIC_ASSERT(sizeof(SENTINAL_STRUCT) == 2+2+8);    
#ifdef USEMI64
    STATIC_ASSERT(IVSIZE == 4);
#endif
#ifdef T_QUAD
    STATIC_ASSERT(sizeof(char *) == 4);
#endif
#ifdef WIN32_API_DEBUG
#define  DUMPMEM(type,name) printf(SDumpStr, #type " " #name, sizeof(((APIPARAM *)0)->name), offsetof(APIPARAM, name));
    DUMPMEM(int,t);
    DUMPMEM(LPBYTE,b);
    DUMPMEM(char,c);
    DUMPMEM(char*,p);
    DUMPMEM(long_ptr,l);
    DUMPMEM(float,f);
    DUMPMEM(double,d);
    printf("(XS)Win32::API::boot: APIPARAM total size=%u\n", sizeof(APIPARAM));
#undef DUMPMEM
#define  DUMPMEM(type,name) printf( \
    "(XS)Win32::API::boot: APICONTROL layout, member %s, SzOf %u, offset %u\n" \
    , #type " " #name, sizeof(((APICONTROL *)0)->name), offsetof(APICONTROL, name));
    DUMPMEM(U32,whole_bf);
    DUMPMEM(U32,inparamlen);
    DUMPMEM(FARPROC, ApiFunction);
    DUMPMEM(SV *, api);
    DUMPMEM(AV *, intypes);
    DUMPMEM(APIPARAM, param);
#undef DUMPMEM
    printf("(XS)Win32::API::boot: APICONTROL total size=%u\n", sizeof(APICONTROL));
#endif	
    //this is not secure against malicious overruns
    //QPC doesn't like unaligned pointers
    if(!QueryPerformanceCounter(&counter))
        croak("Win32::API::boot: internal error\n");
    sentinal_struct.counter = counter;
    sentinal_struct.null1 = L'\0';
    sentinal_struct.null2 = L'\0';
    {
        MY_CXT_INIT;
        sentinal = initSharedKeys(aTHX_ &(MY_CXT));
    }
    sv_setpvn(sentinal, (char*)&sentinal_struct, sizeof(sentinal_struct));
    {
    HV * stash = gv_stashpv("Win32::API", TRUE);
    //you can't ifdef inside a macro's parameters
#ifdef UNICODE
        newCONSTSUB(stash, "IsUnicode",&PL_sv_yes);
#else
        newCONSTSUB(stash, "IsUnicode",&PL_sv_no);
#endif
#ifdef __GNUC__
        newCONSTSUB(stash, "IsGCC",&PL_sv_yes);
#else
        newCONSTSUB(stash, "IsGCC",&PL_sv_no);
#endif
/*only used by tests with eval guard, dont create it on non-debugging to save memory*/
#ifdef WIN32_API_DEBUG
        newCONSTSUB(stash, "IsWIN32_API_DEBUG",&PL_sv_yes);
#endif
    {
    typedef struct {
        unsigned char len;
        unsigned char constval;
    } CONSTREG;
#pragma pack(push)
#pragma pack(push, 1)
    PORTALIGN(1)
    static const struct {
#define XMM(y)        CONSTREG cr_##y; char arr_##y [sizeof(#y)];
    XMM(T_VOID)
    XMM(T_NUMBER)
    XMM(T_POINTER)
    XMM(T_INTEGER)
    XMM(T_SHORT)
#ifndef _WIN64
    XMM(T_QUAD)
#endif
    XMM(T_CHAR)
    XMM(T_NUMCHAR)
    
    XMM(T_FLOAT)
    XMM(T_DOUBLE)
    XMM(T_STRUCTURE)
    
    XMM(T_POINTERPOINTER)
    XMM(T_CODE)
    
    XMM(T_FLAG_UNSIGNED)
    XMM(T_FLAG_NUMERIC)
#undef XMM
    } const_init = {
#define XMM(y)        { sizeof(#y)-1, y}, #y,
    XMM(T_VOID)
    XMM(T_NUMBER)
    XMM(T_POINTER)
    XMM(T_INTEGER)
    XMM(T_SHORT)
#ifndef _WIN64
    XMM(T_QUAD)
#endif
    XMM(T_CHAR)
    XMM(T_NUMCHAR)
    
    XMM(T_FLOAT)
    XMM(T_DOUBLE)
    XMM(T_STRUCTURE)
    
    XMM(T_POINTERPOINTER)
    XMM(T_CODE)
    
    XMM(T_FLAG_UNSIGNED)
    XMM(T_FLAG_NUMERIC)
#undef XMM
    };
#pragma pack(pop)
#pragma pack(pop)
    CONSTREG * entry = (CONSTREG *)&const_init;
    while((DWORD_PTR)entry < (DWORD_PTR)&const_init+sizeof(const_init)){
        newCONSTSUB(stash, (char *)((DWORD_PTR)entry+sizeof(CONSTREG)), newSVuv(entry->constval));
        /* +1 is jump past null */
        entry = (CONSTREG *)((DWORD_PTR) entry + sizeof(CONSTREG) + entry->len + 1);
    }
    }/* Perl constant init struct */
    }/* stash scope */
}

#if IVSIZE == 4

void
UseMI64(...)
PREINIT:
    SV * self;
    APICONTROL * control;
PPCODE:
    if (items < 1 || items > 2)
       croak_xs_usage(cv,  "self [, FlagBool]");
    self = ST(0);
	if (!(SvROK(self) && ((self = SvRV(self)),
                          (SvFLAGS(self) & (SVs_OBJECT|SVs_RMG|SVt_MASK))
                          == (SVs_OBJECT|SVs_RMG|SVt_PVMG))))
    /* I dont think an upgrade to > SVt_PVMG, like SVt_PVLV, will ever happen
      unless someone went inside the object */
    /* add a SvCUR APICONTROL check ?? */
        croak("%s: %s is not of type Win32::API [::More]",
			"Win32::API::UseMI64",
			"self");
    //key always exists
    control = (APICONTROL *)SvPVX(self);
    PUSHs(boolSV(control->UseMI64)); //ST(0) now gone
    PUTBACK;
    
    if(items == 2){
        control->UseMI64 = sv_true(ST(1));
    }
    return; /* dont call PUTBACK again */
    

#endif

HINSTANCE
LoadLibrary(name)
    char *name;
CODE:
    RETVAL = LoadLibrary(name);
OUTPUT:
    RETVAL

long_ptr
GetProcAddress(library, name)
    HINSTANCE library;
    char *name;
CODE:
    RETVAL = (long_ptr) GetProcAddress(library, name);
OUTPUT:
    RETVAL

bool
FreeLibrary(library)
    HINSTANCE library;
CODE:
    RETVAL = FreeLibrary(library);
OUTPUT:
    RETVAL


#//ToUnicode, never make this public API without rewrite, terrible design
#//no use of SvCUR, no use of svutf8 flag, no writing into XSTARG, malloc usage
#//Win32 the mod has much nicer converters in XS

void
ToUnicode(string)
    LPCSTR string
PREINIT:
    LPWSTR uString = NULL;
    int uStringLen;
PPCODE:
    uStringLen = MultiByteToWideChar(CP_ACP, 0, string, -1, uString, 0);
    if(uStringLen) {
        uString = (LPWSTR) safemalloc(uStringLen * 2);
        if(MultiByteToWideChar(CP_ACP, 0, string, -1, uString, uStringLen)) {
            XST_mPV(0, (char *) uString);
            safefree(uString);
            XSRETURN(1);
        } else {
            safefree(uString);
            XSRETURN_NO;
        }
    } else {
        XSRETURN_NO;
    }

#//FromUnicode, never make this public API without rewrite, terrible design
#//no use of SvCUR, no usage of svutf8, no writing into XSTARG, malloc usage
#//Win32 the mod has much nicer converters in XS

void
FromUnicode(uString)
    LPCWSTR uString
PREINIT:
    LPSTR string = NULL;
    int stringLen;
PPCODE:
    stringLen = WideCharToMultiByte(CP_ACP, 0, uString, -1, string, 0, NULL, NULL);
    if(stringLen) {
        string = (LPSTR) safemalloc(stringLen);
        if(WideCharToMultiByte(CP_ACP, 0, uString, -1, string, stringLen, NULL, NULL)) {
            XST_mPV(0, (char *) string);
            safefree(string);
            XSRETURN(1);
        } else {
            safefree(string);
            XSRETURN_NO;
        }
    } else {
        XSRETURN_NO;
    }


    # The next two functions
    # aren't really needed.
    # I threw them in mainly
    # for testing purposes...

void
PointerTo(...)
PREINIT:
    SV * Target;
CODE:
    if (items != 1)//must be CODE:
       croak_xs_usage(cv,  "Target");
    Target = *SP;
    SETs(sv_2mortal(newSViv((IV)SvPV_nolen(Target))));
    /* PUTBACK not needed, we got SP at +1 b/c of items check above, we return
      one item, so no need to assign SP to global SP */
    return;

void
PointerAt(addr)
    long_ptr addr
PPCODE:
    XST_mPV(0, (char *) addr);
    XSRETURN(1);

# IsBadStringPtr is not public API of Win32::API

void
IsBadReadPtr(addr, len)
    long_ptr addr
    UV len
ALIAS:
    IsBadStringPtr = 1
PREINIT:
    SV * retsv;
PPCODE:
    if(ix){
        if(IsBadStringPtr((void *)addr,len)) goto RET_YES;
        else goto RET_NO;
    }
    if(IsBadReadPtr((void *)addr,len)){
        RET_YES:
        retsv = &PL_sv_yes;
    }
    else{
        RET_NO:
        retsv = &PL_sv_no;
    }
    PUSHs(retsv);


void
ReadMemory(...)
PREINIT:
    SV * targ;
	long_ptr	addr;
	IV	len;
CODE:
    if (items != 2)
       croak_xs_usage(cv,  "addr, len");
	{SV * TmpIVSV = POPs;
    len = (IV)SvIV(TmpIVSV);};
	{SV * TmpPtrSV = *SP;
    addr = INT2PTR(long_ptr,SvIV(TmpPtrSV));};
    targ = getTarg(aTHX);
    SETs(targ);
    PUTBACK;
    sv_setpvn_mg(targ, (char *) addr, len);
    return;

#//idea, one day length is optional, 0/undef/not present means full length
#//but this sub is more dangerous then
void
WriteMemory(destPtr, sourceSV, length)
PREINIT:
    SV ** dummy = PUTBACK; /* risky for breakage */
INPUT:
    long_ptr destPtr
    SV * sourceSV
    size_t length;
PREINIT:
    char * sourcePV;
    STRLEN sourceLen;
PPCODE:
    sourcePV = SvPV(sourceSV, sourceLen);
	if(length > sourceLen)
        croak("%s, $length > length($source)", "Win32::API::WriteMemory");
    //they can't overlap so use faster memcpy
    memcpy((void *)destPtr, (void *)sourcePV, length);
    return;

void
_TruncateToWideNull(sv)
    SV * sv
PREINIT:
    WCHAR * str;
    WCHAR * strend;
/* VC 2003 keeps this stack var's liveness around too much due bad code gen because
   of &len in SvPV_force, use a 2nd var for the rest of the body so the var can be registered */
    STRLEN lenp;
    STRLEN len;
PPCODE:
    PUTBACK;
    str = (WCHAR *) SvPV_force(sv, lenp);
    len = lenp;
    if(len & 0x01)
        croak("Win32::API::_TruncateToWideNull: string with utf16 has an odd number of bytes");
    strend = (WCHAR *)((char*)str+len);
    /* wmemchr isn't available from C mode with VC, its an inline C++ function,
       not a CRT DLL export, so make our own */
    for(; str < strend && *str != 0; str++) {};
    len = len - ((size_t)strend - (size_t)str);
    if(SvCUR(sv) != len) {
        SvCUR_set(sv, len);
        SvSETMAGIC(sv);
    }
    return;

void
MoveMemory(Destination, Source, Length)
PREINIT:
    SV ** dummy = PUTBACK; /* risky for breakage */
INPUT:
    long_ptr Destination
    long_ptr Source
    size_t Length
PPCODE:
    MoveMemory((void *)Destination, (void *)Source, Length);
    return;

void
SafeReadWideCString(wstr)
    long_ptr wstr
PREINIT:
    SV * targ;
PPCODE:
    targ = getTarg(aTHX);
    PUSHs(targ);
    PUTBACK;
    if(wstr && ! IsBadStringPtrW((LPCWSTR)wstr, ~0)){
//WCTMB internally will do a dedicated len loop,
//not check NULL on the fly during the conversion, so cache it
//if a portable SEH is ever made, a rewrite combining SEH and wcslen
//is needed so CPU takes 1 instead of 2 passes through the string
        char * dest;
        size_t wlen_long = wcslen((LPCWSTR)wstr);
        int wlen;
        int len;
        BOOL use_default = FALSE;
        BOOL * use_default_ptr;    
        UINT CodePage;
        DWORD dwFlags;
        if(wlen_long > INT_MAX) croak("%s wide string overflowed >" STRINGIFY(INT_MAX), "Win32::API::SafeReadWideCString");
        wlen = (int) wlen_long;
        use_default_ptr = &use_default;
        CodePage = CP_ACP;
        dwFlags = WC_NO_BEST_FIT_CHARS;
        
        retry:
        len = WideCharToMultiByte(CodePage, dwFlags, (LPCWSTR)wstr, wlen, NULL, 0, NULL, NULL);
        dest = sv_grow(targ, (STRLEN)len+1); /*access vio on macro*/
        len = WideCharToMultiByte(CodePage, dwFlags, (LPCWSTR)wstr, wlen, dest, len, NULL, use_default_ptr);
        if (use_default) {
            SvUTF8_on(targ);
            /*this branch will never be taken again*/
            use_default = FALSE;
            use_default_ptr = NULL;
            CodePage = CP_UTF8;
            dwFlags = 0;
            goto retry;
        }
        if (len) {
            SvCUR_set(targ, len);
            SvPVX(targ)[len] = '\0';
        }
        SvPOK_on(targ); //zero length string on error/WCTMB len 0
    }
    //else stays undef
    SvSETMAGIC(targ);
    return;

#this is not public API, let us create a proper OOP
#HMODULE class before exposing DLL Handles to the user, see TODO

void
GetModuleFileName(module)
    HMODULE module
PREINIT:
    SV * targ = getTarg(aTHX);
    DWORD nSize = MAX_PATH;
    WCHAR * lpFilename = (WCHAR *)_alloca(MAX_PATH * sizeof(WCHAR) /*MAXPATH*/);
    DWORD retSize;
CODE:
    /* careful, complicated but efficient stack manipulation here */
    *SP = targ;
    PUTBACK;
    retry:
    retSize = GetModuleFileNameW(module, lpFilename, nSize);
    if(retSize){
        if(retSize == nSize){
    /*TLDR, a 65 KB path is highly unlikely, but still safe, and alloca is fine
        
    note, the original alloca alloc isn't freeded, so don't eat away at the C stack
    too aggressively, if something goes impossibly wrong with GetModuleFileNameW, a stack
    overflow will occur, on normal EXE's C stack is usually reserved for 1 MB,
    max unicode path possible is 32K characters, so 65 KB, we permanently alloced
    alot of pages, probably not, since Perl_peep/Perl_scalarvoid and friends
    are very recursive and like to blow alot of stack during BEGIN/compiling
    so at Perl Code runtime there actually are a couple pages free of C stack.*/
            lpFilename = (WCHAR *)_alloca((nSize += 256) * sizeof(WCHAR));
            goto retry;
        }
        w32sv_setwstr(aTHX_ targ, lpFilename, retSize+1);
    }
    /*else return undef, targ is already undef and pushed earier*/
    return;

# use ... to avoid overhead of items check+croak, this is a private xsub
#ifdef PERL_IMPLICIT_CONTEXT
void
_my_cxt_clone(...)
CODE:
    /* this sub might be returning everything it is passed */
    PUTBACK; /* some vars go out of scope now in machine code */
    {
        MY_CXT_CLONE; /* a redundant memcpy() on this line */
        /* get the SVs for this interp, not the parent interp*/
        initSharedKeys(aTHX_ &(MY_CXT));
    }
    return; /* dont execute another implied XSPP PUTBACK */

#endif

#ifdef ISDEV
IV
_xxSetLastError(in)
    IV in
PREINIT:
    const union {
        void (__stdcall * normal) (DWORD);
        BOOL (__stdcall * special) (DWORD);
    } SLR_u = {SetLastError};
CODE:
    RETVAL = (IV) SLR_u.special((DWORD)in);
OUTPUT:
    RETVAL

#endif

# xsub to attach a hidden SV in RV inside to the target SV of RV outside
# both params must be references
# void SetMagicSV(outside, inside)
void
SetMagicSV(...)
PREINIT:
    SV * outside;
    SV * inside;
CODE:
    if(items != 2)
        croak_xs_usage(cv, "outside, inside");
    inside = POPs;
    outside = POPs;
    PUTBACK;
    if(SvROK(outside) && SvROK(inside)) {
        outside = SvRV(outside);
        inside = SvRV(inside);
    }
    else{
        croak_xs_usage(cv, "outside, inside");
    }
    setMgSV(aTHX_ outside, inside);
    return;

# $ref_to_inside = GetMagicSV($ref_to_outside)
void
GetMagicSV(...)
PREINIT:
    SV * outside;
    SV * inside;
CODE:
    if(items != 1)
    croak:
        croak_xs_usage(cv,  "reference");
    outside = *SP;
    if(!SvROK(outside))
        goto croak;
    outside = SvRV(outside);
    inside = getMgSV(aTHX_ outside);
    if(!inside)
        goto croak;
    *SP = sv_2mortal(newRV_inc(inside));
    /* no PUTBACK, got 1 item, returning 1 item */
    return;

# subname must be a string in ::Import
# void _ImportXS($apiobj, $subname)
void
_ImportXS(...)
PREINIT:
    char * subname;
#if (PERL_REVISION == 5 && PERL_VERSION < 9)
    char* file = __FILE__;
#else
    const char* file = __FILE__;
#endif
CODE:
    assert(items == 2);
    /*if(items != 2)
        croak_xs_usage(cv,  "api, subname");*/
    {   SV * sv = POPs;
        subname = SvPVX(sv);    }
    {   SV * api = POPs;
        PUTBACK;
    {   CV * cv = newXS(subname, XS_Win32__API_ImportCall, file);
        XSANY.any_ptr = (APICONTROL *) SvPVX(SvRV(api));
        setMgSV(aTHX_ (SV*)cv, api);  }}
    return;

#internal use only, makes SV assumptions
void
_Align(sv, boundary)
    SV * sv
    size_t boundary
PREINIT:
    char * buffer;
    size_t remainder;
    char * newbuffer;
    size_t orig_len;
PPCODE:
    PUTBACK;
    if(((size_t)SvPVX(sv) % boundary) != 0){
        buffer = sv_grow(sv, SvCUR(sv)+boundary -1);
        if((remainder = (size_t) buffer % boundary) != 0){
            remainder = boundary - remainder;
            orig_len = SvCUR(sv);
            SvCUR_set(sv, orig_len+remainder);
            memmove((newbuffer= buffer+remainder), buffer, orig_len+1);//+1 for null char
            sv_chop(sv, newbuffer);
        }
    }
#ifndef NDEBUG
    if(((size_t) SvPVX(sv)% boundary) != 0 || *(SvPVX(sv) + SvCUR(sv)) != '\0')
        croak("bad alignment");
#endif
    return;

#ifdef WIN32_API_PROF
void
_DumpTimes()
CODE:
    printf("dumptimes start %I64u loopprep %I64u loopstart %I64u Call_asm_b4 %I64u Call_asm_after %I64u rtn_time\n",
    start_loopprep.QuadPart, loopprep_loopstart.QuadPart, loopstart_Call_asm_b4.QuadPart, Call_asm_b4_Call_asm_after.QuadPart, Call_asm_after_return_time.QuadPart);

#endif

#ifdef WIN32_API_PROF
void
_ResetTimes()
CODE:
    start_loopprep.QuadPart = 0,
    loopprep_loopstart.QuadPart = 0,
    loopstart_Call_asm_b4.QuadPart = 0,
    Call_asm_b4_Call_asm_after.QuadPart = 0,
    Call_asm_after_return_time.QuadPart = 0;

#endif
