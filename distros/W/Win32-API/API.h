/*
    # Win32::API - Perl Win32 API Import Facility
    #
    # Version: 0.45
    # Date: 10 Mar 2003
    # Author: Aldo Calpini <dada@perl.it>
    # Maintainer: Cosimo Streppone <cosimo@cpan.org>
    #
 */

#define NEED_sv_2pv_flags
#define NEED_newSVpvn_share
#include "ppport.h"

/* see https://rt.cpan.org/Ticket/Display.html?id=80217
  http://gcc.gnu.org/bugzilla/show_bug.cgi?id=35124
  http://gcc.gnu.org/bugzilla/show_bug.cgi?id=41001
  undo this if that bug is ever fixed
*/
#ifdef __CYGWIN__
#  define _alloca(size) __builtin_alloca(size)
/* Cygwin-64 doesn't define WIN64 */
#  if defined(_WIN64) && !defined(WIN64)
#    define WIN64
#  endif
#  define stricmp strcasecmp
#  define strnicmp strncasecmp
#endif

/* old (5.8 ish) strawberry perls/Mingws somehow dont ever include malloc.h from
  perl.h, so this include is needed for alloca */
#include <malloc.h>

/* some Mingw GCCs use Static TLS on all DLLs, DisableThreadLibraryCalls fails
   if DLL has Static TLS, todo, figure out how to disable Static TLS on Mingw
   Win32::API never uses it, also Win32::API never uses C++ish exception handling
   see https://rt.cpan.org/Public/Bug/Display.html?id=80249 and
   http://www.cygwin.com/ml/cygwin-apps/2010-03/msg00075.html
*/

#ifdef _MSC_VER
#define DISABLE_T_L_CALLS STMT_START {if(!DisableThreadLibraryCalls(hinstDLL)) return FALSE;} STMT_END
#else
#define DISABLE_T_L_CALLS STMT_START { 0; } STMT_END
#endif

#ifdef __GNUC__
#  define PORTALIGN(x) __attribute__((aligned(x)))
#elif defined(_MSC_VER)
#  if _MSC_VER > 1200
#    define PORTALIGN(x) __declspec(align(x))
#  else
/* have to manually add padding on VC 6, __declspec(align doesn't exist
   and #pragma pack can only decrease alignment not increase it
   C2485: 'align' : unrecognized extended attribute
   */
#    define PORTALIGN(x)
#  endif
#else
#  error unknown compiler
#endif

// #define WIN32_API_DEBUG

#ifdef WIN32_API_DEBUG
#  define WIN32_API_DEBUGM(x) x
#else
#  define WIN32_API_DEBUGM(x)
#endif


/* turns on profiling, use only for benchmark.t, DO NOT ENABLE in CPAN RELEASE
   not all return paths in Call() get the current time (incomplete
   implementation), VC only
*/
//#define WIN32_API_PROF

#ifdef WIN32_API_PROF
#  define WIN32_API_PROFF(x) x
#else
#  define WIN32_API_PROFF(x)
#endif

#ifdef WIN32_API_PROF
LARGE_INTEGER        my_freq = {0};
LARGE_INTEGER        start = {0};
LARGE_INTEGER        loopprep = {0};
LARGE_INTEGER        loopstart = {0};
LARGE_INTEGER        Call_asm_b4 = {0};
LARGE_INTEGER        Call_asm_after = {0};
LARGE_INTEGER        return_time = {0};
LARGE_INTEGER        return_time2 = {0};

LARGE_INTEGER        start_loopprep = {0};
LARGE_INTEGER        loopprep_loopstart = {0};
LARGE_INTEGER        loopstart_Call_asm_b4 = {0};
LARGE_INTEGER        Call_asm_b4_Call_asm_after = {0};
LARGE_INTEGER        Call_asm_after_return_time = {0};
#  ifndef WIN64
__declspec( naked )  unsigned __int64 rdtsc () {
                    __asm
                {
                    mov eax, 80000000h
                    push ebx
                    cpuid
                    _emit 0xf
                    _emit 0x31
                    pop ebx
                    retn
                }
}
/* note: not CPU affinity locked on x86, visually discard high time iternations */
#    define W32A_Prof_GT(x) ((x)->QuadPart = rdtsc())
#  else
#    define W32A_Prof_GT(x) (QueryPerformanceCounter(x))
#  endif
#endif

#ifdef _WIN64
typedef long long long_ptr;
typedef unsigned long long ulong_ptr;
#else
typedef long long_ptr;
typedef unsigned long ulong_ptr;
#endif

/* VC 6 doesn't know what a DWORD_PTR is */
#if defined(_MSC_VER) && _MSC_VER < 1300
typedef DWORD DWORD_PTR;
#endif

#define T_VOID				0
#define T_NUMBER			1
#define T_INTEGER			2
#define T_SHORT				3
#define T_CHAR				4
#define T_NUMCHAR			5
//high processing group
#define T_POINTER			6
#define T_STRUCTURE			7
#define T_POINTERPOINTER		8
#define T_CODE				9
//end of high processing group
#define T_FLOAT 			10
//on 32 bits everthing below needs 2 pushes b/c 8 bytes
#define T_DOUBLE			11
//T_QUAD means a pointer is not 64 bits
//T_QUAD is also used in ifdefs around the C code implementing T_QUAD
#ifndef _WIN64
#  define T_QUAD			12
#  if ! (IVSIZE == 8)
//USEMI64 Perl does not have native i64s, use 8 byte strings or Math::Int64s to emulate
#    define USEMI64
#  endif
#endif

#define T_FLAG_UNSIGNED     (0x80)
#define T_FLAG_NUMERIC      (0x40)

typedef char  *ApiPointer(void);
typedef long   ApiNumber(void);
typedef float  ApiFloat(void);
typedef double ApiDouble(void);
typedef void   ApiVoid(void);
typedef int    ApiInteger(void);
typedef short  ApiShort(void);
#ifdef T_QUAD
typedef __int64 ApiQuad(void);
#endif

typedef struct {
union {
	LPBYTE b;
	char c;
    short s;
	char *p;
	long_ptr l; // 4 bytes on 32bit; 8 bytes on 64bbit; not sure if it is correct
	ulong_ptr ul;
	float f;
	double d;
#ifdef T_QUAD
    __int64 q;
#endif
};
	unsigned char t; //1 bytes, union is 8 bytes, put last to avoid padding
        /* next 2 members exist because the space is free */
        unsigned char unused1;
        unsigned short unused2;
        unsigned short idx0; /* 0 counted position of this APIPARAM struct in array */
        unsigned short idx1; /* 1 counted position of this APIPARAM struct in array */
} APIPARAM;

/* a version of APIPARAM without a "t" type member */
typedef struct {
union {
	LPBYTE b;
	char c;
    short s;
	char *p;
	long_ptr l; // 4 bytes on 32bit; 8 bytes on 64bbit; not sure if it is correct
	ulong_ptr ul;
	float f;
	double d;
#ifdef T_QUAD
    __int64 q;
#endif
};
} APIPARAM_U;

typedef struct {
	SV* object;
	int size;
} APISTRUCT;

typedef struct {
	SV* object;
} APICALLBACK;

/* bitfield is 4 bytes, low to high diagram\|/
   char flags, short stackunwind, char outType
   note the stackunwind is unaligned
*/

#define CTRL_IS_MORE 0x10
#define CTRL_HAS_PROTO 0x20
typedef struct {
    union {
        struct {
            unsigned int convention: 3;
            unsigned int UseMI64: 1;
            unsigned int is_more: 1;
            unsigned int has_proto: 1;
#ifndef _WIN64
            unsigned int reserved: 2;
/* remember to change Call_asm in API::Call() if this is changed */
            unsigned int stackunwind: 16;
#else
            unsigned int reserved: 18;
#endif
            unsigned int out: 8;
        };
        U32 whole_bf;
    };
    U32 inparamlen; /*in units of sizeof(SV *) for comparison to items_sv
                     param count limited to 65K in API.pm so 32 bit lengths
                     dont overflow*/
    FARPROC ApiFunction;
    SV * api; /* a non-ref counted weak RV to the blessed SVPV that holds
                APICONTROL, used to optimize method calls on the API obj, the
                refcount for the RV is stored in the obj's hidden hash*/
    /* this AV is here for no func call look up of it, intypes may be NULL,
       refcnt owned by obj's hidden hash*/
    AV * intypes;
    /* a padding hole here, VC6 doesn't support increasing alignment */
#if defined(_MSC_VER) && _MSC_VER <= 1200
    U32 padding1;
    U32 padding2;
#endif
    PORTALIGN(16) APIPARAM param;
} APICONTROL;

#define APICONTROL_CC_STD 0
#define APICONTROL_CC_C 1
/* fastcall, thiscall, regcall, will go here */

#define STATIC_ASSERT(expr) ((void)sizeof(char[1 - 2*!!!(expr)]))
/*
  because of unknown alignment where the sentinal is placed after the PV
  buffer, put 2 wide nulls, some permutation will be 1 aligned wide null char

  http://gcc.gnu.org/bugzilla/show_bug.cgi?id=28679 bug on Strawberry Perl
  5.8.9 which includes "gcc (GCC) 3.4.5 (mingw-vista special r3)", reported as

In file included from API.c:28:
API.h:122: warning: malformed '#pragma pack(push[, id], <n>)' - ignored
API.h:130: warning: #pragma pack (pop) encountered without matching #pragma pack
 (push, <n>)

  This causes 4 extra unused padding bytes to be placed after null2, which can
  be a performance degradation
*/
#pragma pack(push)
#pragma pack(push, 1)
typedef struct {
    wchar_t null1;
    wchar_t null2;
    LARGE_INTEGER counter;
} SENTINAL_STRUCT;
#pragma pack(pop)
#pragma pack(pop)

#ifndef mPUSHs
#  define mPUSHs(s)                      PUSHs(sv_2mortal(s))
#endif
#ifndef mXPUSHs
#  define mXPUSHs(s)                     XPUSHs(sv_2mortal(s))
#endif

/* a no grow version of PUSHMARK */
#define W32APUSHMARK(p)						\
	STMT_START {						\
	    ++PL_markstack_ptr;					\
	    *PL_markstack_ptr = (I32)((p) - PL_stack_base);	\
	} STMT_END

//all callbacks in Call() or helpers for Call() must static assert against this
//this is the ONE and only stack extend done in Call() and its helpers
//for callbacks, this eliminates half a dozen EXTENDs and replaced them
//with static asserts
#define CALL_PL_ST_EXTEND 3

#if PERL_BCDVERSION >= 0x5007001
#  define PREP_SV_SET(sv) if(SvTHINKFIRST((sv))) sv_force_normal_flags((sv), SV_COW_DROP_PV)
#else
#  define PREP_SV_SET(sv) if(SvTHINKFIRST((sv))) sv_force_normal((sv))
#endif
//C=Callback, CIATP=Callback::IATPatch
#define W32AC_T HV
#define W32ACIATP_T HV
/*no idea why this is defined to 0 but we need this as a label*/
#undef ERROR

#ifndef WC_NO_BEST_FIT_CHARS
#  define WC_NO_BEST_FIT_CHARS 0x00000400
#endif

#ifndef PERL_ARGS_ASSERT_CROAK_XS_USAGE
#define PERL_ARGS_ASSERT_CROAK_XS_USAGE assert(cv); assert(params)

/* prototype to pass -Wmissing-prototypes */
STATIC void
S_croak_xs_usage(pTHX_ const CV *const cv, const char *const params);

STATIC void
S_croak_xs_usage(pTHX_ const CV *const cv, const char *const params)
{
    const GV *const gv = CvGV(cv);

    PERL_ARGS_ASSERT_CROAK_XS_USAGE;

    if (gv) {
        const char *const gvname = GvNAME(gv);
        const HV *const stash = GvSTASH(gv);
        const char *const hvname = stash ? HvNAME(stash) : NULL;

        if (hvname)
            Perl_croak_nocontext("Usage: %s::%s(%s)", hvname, gvname, params);
        else
            Perl_croak_nocontext("Usage: %s(%s)", gvname, params);
    } else {
        /* Pants. I don't think that it should be possible to get here. */
        Perl_croak_nocontext("Usage: CODE(0x%"UVxf")(%s)", PTR2UV(cv), params);
    }
}

#ifdef PERL_IMPLICIT_CONTEXT
#define croak_xs_usage(a,b)	S_croak_xs_usage(aTHX_ a,b)
#else
#define croak_xs_usage		S_croak_xs_usage
#endif

#endif

#define PERL_VERSION_LE(R, V, S) (PERL_REVISION < (R) || \
(PERL_REVISION == (R) && (PERL_VERSION < (V) ||\
(PERL_VERSION == (V) && (PERL_SUBVERSION <= (S))))))

#if PERL_VERSION_LE(5, 13, 8)
STATIC MAGIC * my_find_mg(SV * sv, int type, const MGVTBL *vtbl){
	MAGIC *mg;
	for (mg = SvMAGIC (sv); mg; mg = mg->mg_moremagic) {
		if (mg->mg_type == type && mg->mg_virtual == vtbl)
			return mg;
	}
	return NULL;
}
#define mg_findext(a,b,c) my_find_mg(a,b,c)
#endif

#if PERL_VERSION_LE(5, 7, 2)
STATIC MAGIC *
my_sv_magicext(pTHX_ SV* sv, SV* obj, int how, MGVTBL *vtable,
		 const char* name, I32 namlen)
{
    MAGIC* mg;

    if (SvTYPE(sv) < SVt_PVMG) {
	(void)SvUPGRADE(sv, SVt_PVMG);
    }
    Newz(702,mg, 1, MAGIC);
    mg->mg_moremagic = SvMAGIC(sv);
    SvMAGIC(sv) = mg;

    /* Some magic sontains a reference loop, where the sv and object refer to
	each other.  To prevent a reference loop that would prevent such
	objects being freed, we look for such loops and if we find one we
	avoid incrementing the object refcount. */
    if (!obj || obj == sv ||
	how == PERL_MAGIC_arylen ||
	how == PERL_MAGIC_qr ||
	(SvTYPE(obj) == SVt_PVGV &&
	    (GvSV(obj) == sv || GvHV(obj) == (HV*)sv || GvAV(obj) == (AV*)sv ||
	    GvCV(obj) == (CV*)sv || GvIOp(obj) == (IO*)sv ||
	    GvFORM(obj) == (CV*)sv)))
    {
	mg->mg_obj = obj;
    }
    else {
	mg->mg_obj = SvREFCNT_inc(obj);
	mg->mg_flags |= MGf_REFCOUNTED;
    }
    mg->mg_type = how;
    mg->mg_len = namlen;
    if (name) {
	if (namlen > 0)
	    mg->mg_ptr = savepvn(name, namlen);
	else if (namlen == HEf_SVKEY)
	    mg->mg_ptr = (char*)SvREFCNT_inc((SV*)name);
	else
	    mg->mg_ptr = (char *) name;
    }
    mg->mg_virtual = vtable;

    mg_magical(sv);
    if (SvGMAGICAL(sv))
	SvFLAGS(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);
    return mg;
}
#  ifdef PERL_IMPLICIT_CONTEXT
#    define sv_magicext(a,b,c,d,e,f)       my_sv_magicext(aTHX_ a,b,c,d,e,f)
#  else
#    define sv_magicext            my_sv_magicext
#  endif
#endif

#ifndef SVt_MASK
#  define SVt_MASK SVTYPEMASK
#endif
