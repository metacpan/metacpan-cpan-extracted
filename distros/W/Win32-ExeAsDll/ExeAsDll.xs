#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

//#define ISDEV 1

#ifdef ISDEV
# define ISDEV_EXPR 1
#else
# define ISDEV_EXPR 0
#endif

#ifdef _MSC_VER
EXTERN_C const IMAGE_IMPORT_DESCRIPTOR __IMPORT_DESCRIPTOR_KERNEL32;
#else
EXTERN_C const IMAGE_IMPORT_DESCRIPTOR _head_lib32_libkernel32_a;
#  define __IMPORT_DESCRIPTOR_KERNEL32 _head_lib32_libkernel32_a
#endif

#ifdef _WIN64
/* copy paste dummy */
EXTERN_C const void * __imp_;

EXTERN_C const void * __imp_GetProcAddress;
EXTERN_C const void * __imp_GetModuleHandleA;
EXTERN_C const void * __imp_InitializeCriticalSection;
EXTERN_C const void * __imp_InitializeCriticalSectionAndSpinCount;
EXTERN_C const void * __imp_DeleteCriticalSection;
EXTERN_C const void * __imp_CreateFileW;
EXTERN_C const void * __imp_SetConsoleCtrlHandler;
EXTERN_C const void * __imp_WriteProcessMemory;
EXTERN_C const void * __imp_VirtualProtect;
EXTERN_C const void * __imp_FreeLibrary;
EXTERN_C const void * __imp_GetModuleFileNameW;
EXTERN_C const void * __imp_GetModuleFileNameA;
EXTERN_C const void * __imp_MultiByteToWideChar;
EXTERN_C const void * __imp_WideCharToMultiByte;
#endif

#define INIT_MAYBE_PROCESS_ATTACH() InitOnProcessAttach()
static BOOL InitOnProcessAttach();
static HMODULE gK32DLL = NULL;
static HMODULE gNTDLL = NULL;

#ifndef _WIN64
EXTERN_C HANDLE WINAPI _imp__CreateFileW (LPCWSTR, DWORD, DWORD, LPSECURITY_ATTRIBUTES, DWORD, DWORD, HANDLE);
EXTERN_C FARPROC WINAPI _imp__GetProcAddress(HMODULE, LPCSTR);
EXTERN_C HMODULE WINAPI _imp__GetModuleHandleA(LPCSTR);
EXTERN_C void WINAPI _imp__InitializeCriticalSection(LPCRITICAL_SECTION);
EXTERN_C BOOL WINAPI _imp__InitializeCriticalSectionAndSpinCount(LPCRITICAL_SECTION, DWORD);
EXTERN_C void WINAPI _imp__DeleteCriticalSection(LPCRITICAL_SECTION);
EXTERN_C BOOL WINAPI _imp__SetConsoleCtrlHandler(PHANDLER_ROUTINE, BOOL);
EXTERN_C BOOL WINAPI _imp__WriteProcessMemory(HANDLE, LPVOID, LPCVOID, SIZE_T, SIZE_T *);
EXTERN_C BOOL WINAPI _imp__VirtualProtect(LPVOID, SIZE_T, DWORD, PDWORD);
EXTERN_C BOOL WINAPI _imp__FreeLibrary(HMODULE);
EXTERN_C HMODULE WINAPI _imp__GetModuleFileNameW(HMODULE, LPWSTR, DWORD);
EXTERN_C HMODULE WINAPI _imp__GetModuleFileNameA(HMODULE, LPSTR, DWORD);
EXTERN_C int WINAPI _imp__MultiByteToWideChar (UINT, DWORD, LPCCH, int, LPWSTR, int);
EXTERN_C int WINAPI _imp__WideCharToMultiByte (UINT, DWORD, LPCWCH, int, LPSTR, int, LPCCH, LPBOOL);
#endif

#define CRT_BLOAT_RMV
#include "wide_xs.h"


static BOOL InitOnProcessAttach() {
    static bool g_did_proc_attach = FALSE;
    bool did_proc_attach = g_did_proc_attach;

    if (!did_proc_attach) {
/* Or do "g_did_proc_attach = TRUE;" here b/c theoretical race between 2 ithreads, combined with
   a perl5XX.dll that STATIC LINKED this XS module so the
   DLL Loader Lock protection that comes with executing inside DllMain()
   doesn't happen. And 1st execution in the WinPerl process of this 1x run
   static C func happens inside
   DynaLoader::bootstrap -> XSUB/CV* ThisXSModule::bootstrap
   and 2 ithreads/2 my_perls/2 OS threads, simul execute
   XSUB/CV* ThisXSModule::bootstrap. Fix would be to use
   loop + InterlockedCompareExcha_*() + 3 constants + Sleep() or pause_intrinsic() */
        __security_init_cookie();
        /* Disabled. Previous versions with less efficient machine code.
        K32Abs_OriginalFirstThunk += PTR2nat(__IMPORT_DESCRIPTOR_KERNEL32.OriginalFirstThunk);
        K32Abs_FirstThunk += PTR2nat(__IMPORT_DESCRIPTOR_KERNEL32.FirstThunk); */

        {
        const Size_t LocalK32Abs_OriginalFirstThunk =
            PTR2nat(&(ImageBase_XSBULK88))
            + PTR2nat(__IMPORT_DESCRIPTOR_KERNEL32.OriginalFirstThunk);
        const Size_t LocalK32Abs_FirstThunk =
            PTR2nat(&(ImageBase_XSBULK88))
            + PTR2nat(__IMPORT_DESCRIPTOR_KERNEL32.FirstThunk);
        K32Abs_DeltaFirstToOrigThunk =
            LocalK32Abs_FirstThunk
            - LocalK32Abs_OriginalFirstThunk;
        gK32DLL = GetModuleHandleW(L"KERNEL32.DLL");
        gNTDLL = GetModuleHandleW(L"NTDLL.DLL");
        g_did_proc_attach = TRUE;
        }
    }
    return TRUE;
}

#include "shellapi.h"
#include "winternl.h"

#ifndef HEAP_LFH
#  define HEAP_LFH 2
#endif

/* #undef dVAR
   #define dVAR (__debugbreak()) */

#ifdef _MSC_VER
#  pragma intrinsic(memcmp)
#  pragma intrinsic(strlen)
#  pragma intrinsic(wcslen)
#  pragma intrinsic(strcmp)
#  pragma intrinsic(memset)
#  pragma intrinsic(memcpy)
#endif

#define MAIN_IDX 0
#define _GMA_IDX 1
#define _GETOSF_IDX 2
#define _QNM_IDX 3
#define _GETENV_IDX 4
#define AV_HMODS_START_IDX 5

/* want EU::PXS to create and set variable CV* cv holding the last next XSUB,
   but we want CC to optimize away this NOOP. */
#define DUMMY_ALIAS_IX (XSANY.any_i32)


#define DEFAULT_EXE_W L"cmd.exe"
#define DEFAULT_EXE_A "cmd.exe"

/* test the '\0' too */
#define EADmemEQs(s1, l, s2) \
        (((sizeof(s2)) == (l)) && memEQ((s1), ASSERT_IS_LITERAL(s2), (sizeof(s2))))
#define EADmem2pEQs(s1, l, s2, s3) \
        ((((sizeof(s2))-1)+(sizeof(s3)) == (l)) \
        && memEQ((s1), ASSERT_IS_LITERAL(s2), sizeof(s2)-1) \
        && memEQ((s1)+((sizeof(s2))-1), ASSERT_IS_LITERAL(s3), sizeof(s3)))
#define EADmem2pNNEQs(s1, l, s2, s3) \
        ((((sizeof(s2)-1)+(sizeof(s3)-1)) == (l)) \
        && memEQ((s1), ASSERT_IS_LITERAL(s2), sizeof(s2)-1) \
        && memEQ(((char*)(s1))+(sizeof(s2)-1), ASSERT_IS_LITERAL(s3), sizeof(s3)-1))

/* compare not inc '\0', str against root str lit "" plus 1 more 'A' or 'W',
   saves on duplicate long strings in the binary */
#define EADmemNNEQsAorW(s1, l, s2) \
    (sizeof(s2) == (l) \
    && memEQ((s1), ASSERT_IS_LITERAL(s2), sizeof(s2)-1) \
    &&  (  *(char*)(PTR2nat(s1)+sizeof(s2)-1) == 'A' \
        || *(char*)(PTR2nat(s1)+sizeof(s2)-1) == 'W'))

#define AWLastCh(s1, s2) (*(char*)(PTR2nat(s1)+sizeof(s2)-2))

#define memEQ_K32STR(_fn,_l,_tok) ((l) == STRLENs(#_tok) && memEQ(_fn,K32FN2STR(_tok),STRLENs(#_tok)))

typedef int (_cdecl * __getmainargs_T)(int *, char ***, char ***, int, /*_startupinfo*/ void *);
typedef intptr_t (_cdecl * _get_osfhandle_T)(int fd);
typedef int (_cdecl * _query_new_mode_T)(void);
typedef int (_cdecl * _get_environ_T)(char ***);
typedef BOOL (__stdcall * SetConsoleCtrlHandler_T)(PHANDLER_ROUTINE HandlerRoutine, BOOL Add);
typedef BOOL (__stdcall * InitializeCriticalSectionEx_T)(LPCRITICAL_SECTION lpCriticalSection,
    DWORD dwSpinCount, DWORD Flags);
typedef LANGID (__stdcall * GetThreadUILanguage_T)(void);
typedef LANGID (__stdcall * SetThreadUILanguage_T)(LANGID LangId);

static BOOL WINAPI HandlerRoutine_hook(DWORD dwCtrlType);

/* Hook childExe's Ctrl-C handler if any. This global must be seen from random
   OS threads, can't be in struct MY_CXT which is TLS/my_perl.
   Set/Cleared around every call to $obj->main(); */
static PHANDLER_ROUTINE gPfnHandlerRoutine = NULL;
static InitializeCriticalSectionEx_T gPfnInitializeCriticalSectionEx = NULL;

/* Global Data */

#define MY_CXT_KEY "Win32::ExeAsDll::_guts" XS_VERSION

typedef struct {
    HV* CSHV;
    HV* classHmod;
    jmp_buf * envp;
    LPWSTR * wargv;
    LPWSTR wOneLineCmdLine;
    LPSTR OneLineCmdLine;
    char ** argv;
    __getmainargs_T currentpfn__getmainargs;
    _get_osfhandle_T currentpfn_get_osfhandle;
    _query_new_mode_T currentpfn_query_new_mode;
    _get_environ_T currentpfn_get_environ;
    XPVMG * SvBodyDtor;
    HANDLE capout;
    HANDLE caperr;
    HANDLE HeapPool;
    HMODULE childExeHmod;
    struct {
      HMODULE hThread;
      DWORD dwDesiredAccess;
      DWORD dwThreadId;
      BOOL  bInheritHandle;
    } ThreadHandleCache;
    int wargc;
    int exitcode;
} my_cxt_t;

START_MY_CXT

static void initMyCxt (pTHX_ pMY_CXT) {
    MY_CXT.classHmod = gv_stashpvn("Win32::ExeAsDll::HMODULE::DESTROY",
        STRLENs("Win32::ExeAsDll::HMODULE"), FALSE);
    MY_CXT.CSHV = newHV();
}

/* UNUSED ATM */
#define SvHOUT(_sv) *((HANDLE*)&(SvCUR(_sv)))
#define SvHERR(_sv) *((HANDLE*)&(SvIVX(_sv)))
#define SvHHEAP(_sv) *((HANDLE*)&(SvNVX(_sv)))

static int mg_dup_ead(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
    CBP;
    return 1;
}

/* arg MAGIC* mg is NULL if called from XSUB main directly */
static int mg_free_ead(pTHX_ SV* sv, MAGIC* mg) {
  HANDLE h;
  if(0 && sv) { /* UNUSED ATM, XSUB ::END() passes NULL in SV* sv */
      h = SvHOUT(sv);
      if(h){
          SvHOUT(sv) = NULL;
          CloseHandle(h);
      }
      h = SvHERR(sv);
      if(h){
          SvHERR(sv) = NULL;
          CloseHandle(h);
      }
      h = SvHHEAP(sv);
      if(h) {
          SvHHEAP(sv) = NULL;
          HeapDestroy(h);
      }
  }
  {
      PHANDLER_ROUTINE HandlerRoutine = gPfnHandlerRoutine;
      if (HandlerRoutine) {
          gPfnHandlerRoutine = NULL;
          SetConsoleCtrlHandler(HandlerRoutine_hook, FALSE);
      }
  }
  {
    dMY_CXT;
    {
        HV* hv = MY_CXT.CSHV;
        HE *he;
        LPCRITICAL_SECTION cs;
        STRLEN kl;
        SV* sviv;
        char* key;
        U32 hash;
        hv_iterinit(hv);
        while((he = hv_iternext(hv))) {
            /* sviv = hv_iterval(hv, he); */
            /* sviv = HeVAL(he); */
            /* cs = (LPCRITICAL_SECTION)PTR2nat(SvIVX(sviv)); */
            /* char* key = hv_iterkey(he, &l); */
            key = HePV(he,kl);
            cs = *((LPCRITICAL_SECTION *)PTR2nat(key));
            hash = HeHASH(he);
            hv_common(hv, NULL, key, kl, 0, HV_DELETE, NULL, hash);
            DeleteCriticalSection(cs);
        }
    }
    h = MY_CXT.HeapPool;
    if (h) {
        MY_CXT.HeapPool = NULL;
        HeapDestroy(h);
    }
    MY_CXT.envp = NULL;
    MY_CXT.childExeHmod = NULL;
    MY_CXT.currentpfn__getmainargs = NULL;
    MY_CXT.currentpfn_get_osfhandle = NULL;
    MY_CXT.currentpfn_query_new_mode = NULL;
    MY_CXT.currentpfn_get_environ = NULL;
    MY_CXT.wOneLineCmdLine = NULL;
    MY_CXT.OneLineCmdLine = NULL;
    MY_CXT.argv = NULL;
    MY_CXT.wargv = NULL;
    /* Any point of making these 2 resources be PL exception proof (RC)?
       Don't think so b/c child EXE doesn't know about the interp and can't
       call into perl5XX.dll to throw a croak()/longjmp(). */
    h = MY_CXT.capout;
    if(h) {
        MY_CXT.capout = NULL;
        CloseHandle(h);
    }
    h = MY_CXT.caperr;
    if(h) {
        MY_CXT.caperr = NULL;
        CloseHandle(h);
    }
  }
  return 1;
}

const static struct mgvtbl vtbl_FreeMainInvkRsrcs = {
	NULL, NULL, NULL, NULL, mg_free_ead, NULL, mg_dup_ead, NULL
};


static AV*
ParseIAT(pTHX_ CV* cv, AV* av, HINSTANCE h);

static  HANDLE __stdcall
GetProcessHeap_hook() {
    dTHX;
    dMY_CXT;
    return MY_CXT.HeapPool;
}

static void _cdecl
exit_hook(int status) {
  dTHX;
  dMY_CXT;
  MY_CXT.exitcode = status;
  longjmp(*MY_CXT.envp, 1);
}

static int _cdecl
__getmainargs_hook( int * argc, char *** argv, char *** env, int doWildCard,
                    /*_startupinfo*/ int* startInfo) {
  dTHX;
  dMY_CXT;
  int ret;
  char** strp = MY_CXT.argv;
  if (strp) {
/* typedef struct {int newmode; } _startupinfo;
   Ignore arg 5, and skip messing with setting/restoring _set_new_mode() and _query_new_mode() */
    *argc = MY_CXT.wargc;
    *argv = strp;
    *startInfo = MY_CXT.currentpfn_query_new_mode();
    ret = MY_CXT.currentpfn_get_environ(env);
  }
  else {
    __getmainargs_T currentpfn__getmainargs = MY_CXT.currentpfn__getmainargs;
    ret = currentpfn__getmainargs(argc,argv,env,doWildCard,startInfo);
  }
  return ret;
}

static LPWSTR WINAPI
GetCommandLineW_hook() {
  dTHX;
  dMY_CXT;
  LPWSTR wstr = MY_CXT.wOneLineCmdLine;
  if(wstr)
    return wstr;
  else
    return GetCommandLineW();
}

static LPSTR WINAPI
GetCommandLineA_hook() {
  dTHX;
  dMY_CXT;
  LPSTR str = MY_CXT.OneLineCmdLine;
  if(str)
    return str;
  else
    return GetCommandLineA();
}


static DWORD WINAPI
GetModuleFileNameA_hook(HMODULE hModule, LPSTR   lpFilename,DWORD   nSize) {
  if(!hModule) {
      dTHX;
      dMY_CXT;
      hModule = MY_CXT.childExeHmod;
  }
  return GetModuleFileNameA(hModule, lpFilename, nSize);
}

static DWORD WINAPI
GetModuleFileNameW_hook(HMODULE hModule,  LPWSTR  lpFilename,  DWORD   nSize) {
  if(!hModule) {
      dTHX;
      dMY_CXT;
      hModule = MY_CXT.childExeHmod;
  }
  return GetModuleFileNameW(hModule, lpFilename, nSize);
}

static DWORD WINAPI
FormatMessageW_hook(DWORD dwFlags, LPCVOID lpSource, DWORD dwMessageId,
  DWORD dwLanguageId, LPWSTR  lpBuffer, DWORD nSize, va_list *Arguments) {
  if(dwFlags & FORMAT_MESSAGE_FROM_HMODULE && lpSource == NULL)  {
    dTHX;
    dMY_CXT;
    lpSource = MY_CXT.childExeHmod;
  }
  return FormatMessageW(dwFlags, lpSource, dwMessageId, dwLanguageId, lpBuffer,
    nSize, Arguments);
}

static DWORD WINAPI
FormatMessageA_hook(DWORD   dwFlags,LPCVOID lpSource,
DWORD   dwMessageId,DWORD   dwLanguageId,LPSTR   lpBuffer,
DWORD   nSize,va_list *Arguments ) {
  if(dwFlags & FORMAT_MESSAGE_FROM_HMODULE && lpSource == NULL) {
    dTHX;
    dMY_CXT;
    lpSource = MY_CXT.childExeHmod;
  }
  return FormatMessageA(dwFlags, lpSource, dwMessageId, dwLanguageId, lpBuffer,
    nSize, Arguments);
}

static void WINAPI
InitializeCriticalSection_hook(LPCRITICAL_SECTION lpCriticalSection){
    InitializeCriticalSection(lpCriticalSection);
    {
        dTHX;
        /* SV* sv = newSViv(PTR2nat(lpCriticalSection)); */
        dMY_CXT;
        SV* sv = &PL_sv_yes;
        hv_store(MY_CXT.CSHV, (char*)&lpCriticalSection, sizeof(lpCriticalSection), sv , 0);
    }
}
static BOOL WINAPI
InitializeCriticalSectionAndSpinCount_hook(LPCRITICAL_SECTION lpCriticalSection, DWORD dwSpinCount){
    BOOL r = InitializeCriticalSectionAndSpinCount(lpCriticalSection, dwSpinCount);
    if(r) {
        dTHX;
        /* SV* sv = newSViv(PTR2nat(lpCriticalSection)); */
        dMY_CXT;
        SV* sv = &PL_sv_yes;
        hv_store(MY_CXT.CSHV, (char*)&lpCriticalSection, sizeof(lpCriticalSection), sv , 0);
    }
    return r;
}
static BOOL WINAPI
InitializeCriticalSectionEx_hook(LPCRITICAL_SECTION lpCriticalSection, DWORD dwSpinCount, DWORD Flags){
    BOOL r = gPfnInitializeCriticalSectionEx(lpCriticalSection, dwSpinCount, Flags);
    if(r) {
        dTHX;
        /* SV* sv = newSViv(PTR2nat(lpCriticalSection)); */
        dMY_CXT;
        SV* sv = &PL_sv_yes;
        hv_store(MY_CXT.CSHV, (char*)&lpCriticalSection, sizeof(lpCriticalSection), sv , 0);
    }
    return r;
}
static void WINAPI
DeleteCriticalSection_hook(LPCRITICAL_SECTION lpCriticalSection){
    DeleteCriticalSection(lpCriticalSection);
    {
        dTHX;
        dMY_CXT;
        hv_delete(MY_CXT.CSHV, (char*)&lpCriticalSection, sizeof(lpCriticalSection), 0);
    }
}

static BOOL WINAPI
HandlerRoutine_hook(DWORD dwCtrlType) {
    PHANDLER_ROUTINE HandlerRoutine = gPfnHandlerRoutine; /* anti-race to be safe */
    if(HandlerRoutine)
        HandlerRoutine(dwCtrlType);
    return FALSE; /* stop K32.dll from exiting the process, and instead call
    the next handler, which is perl5XX.dll's fn ptr. */
}

static BOOL WINAPI
SetConsoleCtrlHandler_hook(PHANDLER_ROUTINE HandlerRoutine, BOOL Add) {
/* TODO consider what happens if a To-Remove HandlerRoutine DOESN'T MATCH
   our global!!! How did HandlerRoutine get added to the Linked List in the
   first place? There is some kind of leak, or something getting partially
   hooked, that nobody can see w/o single stepping. That is bad.
   This should probably should be:
      if(REMOVE && HandlerRoutine != gHandlerRoutine)
          croak_nocontext("SetConsoleCtrlHandler_hook broken/leaking"); */
    if(!Add)
        gPfnHandlerRoutine = NULL;
    else
        gPfnHandlerRoutine = HandlerRoutine;
    return SetConsoleCtrlHandler(HandlerRoutine_hook, Add);
}

static intptr_t _cdecl
_get_osfhandle_hook(int fd) {
    dTHX;
    dMY_CXT;
    if(fd == 1 && MY_CXT.capout)
      return (intptr_t)MY_CXT.capout;
    else if (fd == 2 && MY_CXT.caperr)
      return (intptr_t)MY_CXT.caperr;
    else
      return MY_CXT.currentpfn_get_osfhandle(fd);
}

/* Too slow, very remote chance of a memory leak. So disable this. */
static BOOL WINAPI
SetThreadLocale_hook(LCID Locale) {
    return TRUE;
}

static LANGID gLastThreadUILanguage; /* uninited until flag set */
static bool gInitedLastThreadUILanguage = FALSE;
static GetThreadUILanguage_T gPfnGetThreadUILanguage = NULL;

static LANGID WINAPI
SetThreadUILanguage_hook(LANGID LangId) {
    if(LangId != 0)
        return LangId;
    else if(gInitedLastThreadUILanguage == FALSE) {
        gInitedLastThreadUILanguage = TRUE;
        gLastThreadUILanguage = gPfnGetThreadUILanguage();
    }
    return gLastThreadUILanguage;
}


static HANDLE WINAPI
OpenThread_hook(DWORD dwDesiredAccess, BOOL  bInheritHandle, DWORD dwThreadId) {
  dTHX;
  dMY_CXT;
  DWORD dwFlags;
  HANDLE h = MY_CXT.ThreadHandleCache.hThread;
  BOOL GHIResult = TRUE;
  if( h
      && dwDesiredAccess == MY_CXT.ThreadHandleCache.dwDesiredAccess
      && bInheritHandle == MY_CXT.ThreadHandleCache.bInheritHandle
      && dwThreadId == MY_CXT.ThreadHandleCache.dwThreadId
      && (GHIResult = GetHandleInformation(h, &dwFlags)))
      return h;
  else {
      HANDLE newh = OpenThread(dwDesiredAccess, bInheritHandle, dwThreadId);
      if (newh) {
        MY_CXT.ThreadHandleCache.hThread = newh;
        MY_CXT.ThreadHandleCache.dwDesiredAccess = dwDesiredAccess;
        MY_CXT.ThreadHandleCache.bInheritHandle = bInheritHandle;
        MY_CXT.ThreadHandleCache.dwThreadId = dwThreadId;
        /* if GHIResult is FALSE, then skip CH() on h, b/c h was tested to be
           a dead handle */
        if(h && GHIResult)
          CloseHandle(h);
      }
      return newh;
  }
}

static char* __cdecl
setlocale_hook(int Category, const char *Locale) {
    return (char*)Locale;
}
static WCHAR* __cdecl
wsetlocale_hook(int Category, const WCHAR* Locale) {
    return (WCHAR*)Locale;
}

static HMODULE WINAPI
GetModuleHandleW_hook(LPCWSTR lpModuleName) {
    if(lpModuleName) {
      if(*(lpModuleName+STRLENs("KERNEL32")) == L'.'
        && ( ( memEQ(lpModuleName+STRLENs("KERNEL32."), L"DLL", sizeof(L"DLL"))
            && memEQ(lpModuleName, L"KERNEL32", sizeof(L"KERNEL32")-2))
          || ( memEQ(lpModuleName+STRLENs("kernel32."), L"dll", sizeof(L"dll"))
            && memEQ(lpModuleName, L"kernel32", sizeof(L"kernel32")-2)))) {
        return gK32DLL;
      }
      else if(*(lpModuleName+STRLENs("NTDLL")) == L'.'
        && (  (memEQ(lpModuleName+STRLENs("NTDLL."), L"DLL", sizeof(L"DLL"))
            && memEQ(lpModuleName, L"NTDLL", sizeof(L"NTDLL")-2))
          ||  (memEQ(lpModuleName+STRLENs("ntdll."), L"dll", sizeof(L"dll"))
            && memEQ(lpModuleName, L"ntdll", sizeof(L"ntdll")-2))  )) {
        return gNTDLL;
      }
        else
            return GetModuleHandleW(lpModuleName);
    }
    else /* MSVC 2022, cheap NULL val in reg vs load int lit val 0 */
        return GetModuleHandleW(lpModuleName);
}

static HMODULE WINAPI
GetModuleHandleA_hook(LPCSTR lpModuleName) {
    if(lpModuleName) {
      if(*(lpModuleName+STRLENs("KERNEL32")) == '.'  /* 4 b/c  chk '\0'*/
        &&((   memEQ(lpModuleName+STRLENs("KERNEL32."), "DLL", sizeof("DLL"))
            && memEQs(lpModuleName, STRLENs("KERNEL32"), "KERNEL32"))
          || ( memEQ(lpModuleName+STRLENs("kernel32."), "dll", sizeof("dll"))
            && memEQs(lpModuleName, STRLENs("kernel32"), "kernel32")))) {
        return gK32DLL;
      }
      else if(*(lpModuleName+STRLENs("NTDLL")) == '.'
        && (
          (memEQ(lpModuleName+STRLENs("NTDLL."), "DLL", sizeof("DLL"))
            && memEQs(lpModuleName, STRLENs("NTDLL"), "NTDLL"))
          || (memEQ(lpModuleName+STRLENs("ntdll."), "dll", sizeof("dll"))
            && memEQs(lpModuleName, STRLENs("ntdll32"), "ntdll")))) {
        return gNTDLL;
      }
      else
        return GetModuleHandleA(lpModuleName);
    }
    else /* ANSI name is NULL, A vs W irrel, W less ops*/
        return GetModuleHandleW((LPCWSTR)lpModuleName);
}
static FARPROC WINAPI
GetProcAddress_hook(HMODULE hModule, LPCSTR lpProcName){
    if(  PTR2nat(lpProcName) > 0xFFFF/* SetThreadUILanguage */
      && memEQ(lpProcName, "SetThrea", 8) && memEQ(lpProcName+8, "dUILangu", 8)
      /* chk '\0' too, 8 long units can't SEGV b/c they won't cross a page line */
      && memEQ(lpProcName+16, "age", 4)) {
        GetThreadUILanguage_T pfnGetThreadUILanguage = gPfnGetThreadUILanguage;
        if(!pfnGetThreadUILanguage) {
          pfnGetThreadUILanguage = (GetThreadUILanguage_T)
            GetProcAddress(hModule, "GetThreadUILanguage");
          if(!pfnGetThreadUILanguage)
            return (FARPROC)pfnGetThreadUILanguage;
          gPfnGetThreadUILanguage = pfnGetThreadUILanguage;
        }
        return (FARPROC)SetThreadUILanguage_hook;
      }
    else
        return GetProcAddress(hModule,lpProcName);
}
static void _cdecl
__set_app_type_hook (int at) {
    return;
}

static HMODULE
LoadPESV(pTHX_ CV* cv, SV* exe_path_sv) {
    WCHAR warr[MAX_PATH];
    WCHAR * wstr;
    int wlen;
    HMODULE h;
    if(exe_path_sv) {
      wlen = MAX_PATH;
      wstr = warr;
      while((wlen = (int)sv_to_wstr_cstk(aTHX_ cv, exe_path_sv, wstr, wlen)) < 0) {
          wlen = -wlen;
          wstr = (WCHAR*)alloca((wlen+4)*2);
      }
    }
    else
      wstr = L"cmd.exe";
    h = LoadLibraryW(wstr);
    return h;
}

static HMODULE
LoadPEPV(pTHX_ CV* cv, const char * dll_path) {
    WCHAR warr[MAX_PATH];
    WCHAR * wstr;
    int wlen;
    HMODULE h;
    int len = (int)strlen(dll_path);
    wlen = MAX_PATH;
    wstr = warr;
    while((wlen = (int)pv_to_wstr_cstk(aTHX_ cv, dll_path, len, wstr, wlen)) < 0) {
        wlen = -wlen;
        wstr = (WCHAR*)alloca((wlen+4)*2);
    }
    h = LoadLibraryW(wstr);
    return h;
}

static HANDLE
CreateCapFile(pTHX_ CV* cv, SV* capfilepath_sv) {
  HANDLE h;
  WCHAR warr[MAX_PATH];
  int wlen = MAX_PATH;
  WCHAR * wstr = warr;
  while((wlen = (int)sv_to_wstr_cstk(aTHX_ cv, capfilepath_sv, wstr, wlen)) < 0) {
      wlen = -wlen;
      wstr = (WCHAR*)alloca((wlen+4)*2);
  }
  h = CreateFileW(wstr,GENERIC_WRITE,
      FILE_SHARE_READ|FILE_SHARE_WRITE,NULL,CREATE_ALWAYS,
      FILE_ATTRIBUTE_TEMPORARY,NULL);
  if(h == INVALID_HANDLE_VALUE) {
      S_croak_sub_glr_k32(cv, CreateFileW);
      h = NULL; /* UNREACHABLE turn INVALID_HANDLE_VALUE -1 -> NULL 0*/
  }
  return h;
}

#undef APPRVA2ABS
#define APPRVA2ABS(x) ((DWORD_PTR)dosHeader + (DWORD_PTR)(x))

static AV* WINAPI
LoadExe(pTHX_ CV* cv, SV* exe_path_sv) {
  HMODULE h = LoadPESV(aTHX_ cv, exe_path_sv);
  const IMAGE_DOS_HEADER * dosHeader = (PIMAGE_DOS_HEADER)h;
  if (dosHeader) {
    if (dosHeader->e_magic == IMAGE_DOS_SIGNATURE) {
      const IMAGE_NT_HEADERS * ntHeader = (PIMAGE_NT_HEADERS)APPRVA2ABS(dosHeader->e_lfanew);
      if (ntHeader && ntHeader->Signature == IMAGE_NT_SIGNATURE) {
        AV* av;
        void (*f)();
        f = (void (*)())((size_t)(ntHeader->OptionalHeader.AddressOfEntryPoint)+(size_t)dosHeader);
        /* HMOD .exe, HMOD k32.dll atleast and 0 base->1 base */
        av = newAV_alloc_xz(AV_HMODS_START_IDX+1+1+1);
        av_store_simple(av, MAIN_IDX, newSViv(PTR2nat(f)));
        av_store_simple(av, AV_HMODS_START_IDX, newSViv(PTR2nat(h)));
        av = ParseIAT(aTHX_ cv, av, h);
        return av;
      }
    }
    FreeLibrary(h);
    SetLastError(ERROR_BAD_EXE_FORMAT);
  }
  return NULL;
}

static AV*
ParseIAT(pTHX_ CV* cv, AV* av, HINSTANCE h) {
    // Find the IAT size
    DWORD ulsize = 0;
    PIMAGE_DOS_HEADER dosHeader = (PIMAGE_DOS_HEADER)h;
    const IMAGE_NT_HEADERS * ntHeader = (PIMAGE_NT_HEADERS)APPRVA2ABS(dosHeader->e_lfanew);
    /* if(ntHeader->OptionalHeader.NumberOfRvaAndSizes >= IMAGE_DIRECTORY_ENTRY_IMPORT) { */
    DWORD pDataDirImportRVA = ntHeader->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress;
    DWORD pDataDirImportSize = ntHeader->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].Size;
    /* skip testing pDataDirImportRVA == 0, unrealistic to see bizzare "packed" .exe'es in wild */
    PIMAGE_IMPORT_DESCRIPTOR importDescriptor = (PIMAGE_IMPORT_DESCRIPTOR)APPRVA2ABS(pDataDirImportRVA);
    HANDLE hp = GetCurrentProcess();
    // Loop names
    for (; importDescriptor->Name; importDescriptor++) {
        PIMAGE_THUNK_DATA OriginalFirstThunk;
        void ** FirstThunk;
        HINSTANCE hImportDLL;
        PSTR pszImportDLLName = (PSTR)((PBYTE)h + importDescriptor->Name);
        if (!pszImportDLLName)
            break;
        hImportDLL = LoadPEPV(aTHX_ cv, pszImportDLLName);
        if (!hImportDLL)
            S_croak_sub_glr(cv, pszImportDLLName /*"LL dep"*/);
        av_store_simple(av, AvFILLp(av)+1, newSViv(PTR2nat(hImportDLL)));
        /* for typical, unbound PE files OriginalFirstThunk and FirstThunk are
           identical values of type void *. Same integer value, holding a RVA.
           If bound, or ExeAsDll gets End User re-entry and LoadLibrary()
           did a RC++ when we called it instead of mmap-ing from new. In this
           case, void** FirstThunk, if bound will be a stale (bad) fnc ptr from
           another system. If 2 ExeAsDll $obj'es, same .exe, void** FirstThunk
           already holds correct value, was linked, and was hooked, and we
           don't need to do any more. PE binding is obsolete >= Vista (ASLR).

           TODO: don't do this link+patch loop a 2nd time on LL() RC++ b/c
           2 ExeAsDll $obj'es, same .exe , efficiency reasons */
        OriginalFirstThunk = (PIMAGE_THUNK_DATA)APPRVA2ABS(importDescriptor->OriginalFirstThunk);
        FirstThunk = (void**)APPRVA2ABS(importDescriptor->FirstThunk);

        /* for each Import fnc, either install our hook or call GetProcAddress() */
        for (; OriginalFirstThunk->u1.Function; FirstThunk++,OriginalFirstThunk++) {
            FARPROC pfnNew = 0;
            if (OriginalFirstThunk->u1.Ordinal & IMAGE_ORDINAL_FLAG) {
                size_t ord = IMAGE_ORDINAL(OriginalFirstThunk->u1.Ordinal);
                warn_nocontext("Saw Imp Ord=%d", ord);
                pfnNew = GetProcAddress(hImportDLL,(LPCSTR)ord);
                if (!pfnNew)
                    S_croak_sub_glr_fn(cv, (const char *)ord);
            }
            else { /* ASCII fn string not ordinal */
                U32 l;
                PSTR fName = (PSTR)(PTR2nat(h) + PTR2nat(OriginalFirstThunk->u1.Function));
                fName += 2; /* skip field U16 Hint */
                l = (U32)strlen(fName); /* faster rejection agaist need-to-hook list */
                if(memEQ_K32STR(fName,l,InitializeCriticalSectionAndSpinCount)) /* 37 */
                  pfnNew = (FARPROC)InitializeCriticalSectionAndSpinCount_hook;
                /* don't memEQ_K32STR(), this Fn is GPAed, not import tabled */
                else if(memEQs(fName, l, "InitializeCriticalSectionEx")) { /* 27 */
                  gPfnInitializeCriticalSectionEx = /* gbl var b/c its from K32 */
                    (InitializeCriticalSectionEx_T)GetProcAddress(hImportDLL,
                    "InitializeCriticalSectionEx");
                  if(!gPfnInitializeCriticalSectionEx)
                    S_croak_sub_glr_fn(cv, "InitializeCriticalSectionEx");
                  pfnNew = (FARPROC)InitializeCriticalSectionEx_hook;
                }
                else if(memEQ_K32STR(fName,l,InitializeCriticalSection)) /* 25 */
                  pfnNew = (FARPROC)InitializeCriticalSection_hook;
                else if(memEQ_K32STR(fName,l,SetConsoleCtrlHandler)) /* 21 */
                  pfnNew = (FARPROC)SetConsoleCtrlHandler_hook;
                else if(memEQ_K32STR(fName,l,DeleteCriticalSection)) /* 21 */
                  pfnNew = (FARPROC)DeleteCriticalSection_hook;
                else if(l == STRLENs("GetModuleFileNameA") /* 16 */
                        && memEQ(fName, K32FN2STR(GetModuleFileNameA), STRLENs("GetModuleFileNameA")-1))
                  pfnNew = AWLastCh(fName,"GetModuleFileNameW") == 'A'
                    ? (FARPROC)GetModuleFileNameA_hook : (FARPROC)GetModuleFileNameW_hook;
                else if((l == STRLENs("SetThreadLocale") || l == STRLENs("SetThreadUILanguage")) /* 15 19 */
                  && memEQs(fName, 8,"SetThrea")
                  && (      memEQs(fName+8, 8,"dLocale") /*8 not 7, 1 op */
                        || (memEQs(fName+8, 8,"dUILangu") && memEQs(fName+16, 4,"age")))) {
                  if(l == STRLENs("SetThreadLocale"))
                    pfnNew = (FARPROC)SetThreadLocale_hook;
                  else {
                    GetThreadUILanguage_T pfnGetThreadUILanguage = gPfnGetThreadUILanguage;
                    if(!pfnGetThreadUILanguage) {
                      pfnGetThreadUILanguage = (GetThreadUILanguage_T)
                        GetProcAddress(hImportDLL, "GetThreadUILanguage");
                      if(!pfnGetThreadUILanguage)
                        S_croak_sub_glr_fn(cv, "GetThreadUILanguage");
                      gPfnGetThreadUILanguage = pfnGetThreadUILanguage;
                    }
                    pfnNew = (FARPROC)SetThreadUILanguage_hook;
                  }
                }
                else if(l == STRLENs("GetModuleHandleA") /* 16 */
                        && memEQ(fName, K32FN2STR(GetModuleHandleA), STRLENs("GetModuleHandleA")-1))
                  pfnNew = AWLastCh(fName,"GetModuleHandle") == 'A'
                    ? (FARPROC)GetModuleHandleA_hook : (FARPROC)GetModuleHandleW_hook;
                else if(EADmemNNEQsAorW(fName, l,"GetCommandLine")) /* 15 */
                  pfnNew = AWLastCh(fName,"GetCommandLine") == 'A'
                    ? (FARPROC)GetCommandLineA_hook : (FARPROC)GetCommandLineW_hook;
                else if(EADmem2pNNEQs(fName, l,"GetProc","essHeap")) /* 14 */
                  pfnNew = (FARPROC)GetProcessHeap_hook;
                else if(EADmem2pNNEQs(fName, l,"GetProc","Address")) /* 14 */
                  pfnNew = (FARPROC)GetProcAddress_hook;
                else if(memEQs(fName, l,"__set_app_type")) /* 14 */
                  pfnNew = (FARPROC)__set_app_type_hook;
                else if(memEQs(fName, l,"_get_osfhandle")) { /* 14 */
                  _get_osfhandle_T currentpfn_get_osfhandle =
                      (_get_osfhandle_T)GetProcAddress(hImportDLL,"_get_osfhandle");
                  if (!currentpfn_get_osfhandle)
                      S_croak_sub_glr_fn(cv, "_get_osfhandle"); /* _get_osfhandle */
                  av_store_simple(av, _GETOSF_IDX, newSViv(PTR2nat(currentpfn_get_osfhandle)));
                  pfnNew = (FARPROC)_get_osfhandle_hook;
                }
                else if(EADmemNNEQsAorW(fName, l,"FormatMessage")) /* 14 */
                  pfnNew = AWLastCh(fName,"FormatMessage") == 'A'
                    ? (FARPROC)FormatMessageA_hook : (FARPROC)FormatMessageW_hook;
                else if(memEQs(fName, l,"__getmainargs")) {/*  13 */
                  _query_new_mode_T currentpfn_query_new_mode;
                  _get_environ_T currentpfn_get_environ;
                  __getmainargs_T currentpfn__getmainargs =
                      (__getmainargs_T)GetProcAddress(hImportDLL,"__getmainargs");
                  if (!currentpfn__getmainargs)
                      S_croak_sub_glr_fn(cv, "__getmainargs");
                  /* stored in obj b/c sym could be from any version CRT dll */
                  av_store_simple(av, _GMA_IDX, newSViv(PTR2nat(currentpfn__getmainargs)));

                  currentpfn_query_new_mode =
                      (_query_new_mode_T)GetProcAddress(hImportDLL,"?_query_new_mode@@YAHXZ");
                  if (!currentpfn_query_new_mode)
                      S_croak_sub_glr_fn(cv, "?_query_new_mode@@YAHXZ");
                  /* stored in obj b/c sym could be from any version CRT dll */
                  av_store_simple(av, _QNM_IDX, newSViv(PTR2nat(currentpfn_query_new_mode)));

                  currentpfn_get_environ =
                      (_get_environ_T)GetProcAddress(hImportDLL,"_get_environ");
                  if (!currentpfn_get_environ)
                      S_croak_sub_glr_fn(cv, "_get_environ");
                  /* stored in obj b/c sym could be from any version CRT dll */
                  av_store_simple(av, _GETENV_IDX, newSViv(PTR2nat(currentpfn_get_environ)));

                  /* return our hook func, not the CRT func */
                  pfnNew = (FARPROC)__getmainargs_hook;
                }
                else if(memEQs(fName, l,"OpenThread")) /* 10 */
                  pfnNew = (FARPROC)OpenThread_hook;
                else if((l == STRLENs("wsetlocale") || l == STRLENs("setlocale"))/* 10, 9 */
                    && (  memEQ(fName, "setlocale", STRLENs("setlocale"))
                          || (  memEQ(fName+1, "setlocale", STRLENs("setlocale"))
                                && *fName == 'w')))
                  pfnNew = l == STRLENs("wsetlocale")
                    ? (FARPROC)wsetlocale_hook : (FARPROC)setlocale_hook;
                else if((l == STRLENs("exit") || l == STRLENs("_exit")) /* 4, 5 */
                    && (  memEQ(fName, "exit", STRLENs("exit"))
                          || (  memEQ(fName+1, "exit", STRLENs("exit"))
                                && *fName == '_')))
                  pfnNew = (FARPROC)exit_hook;
                else {
                  pfnNew = GetProcAddress(hImportDLL,fName);
                  if (!pfnNew)
                      S_croak_sub_glr_fn(cv, fName);
                }
            }  /* don't do the syscalls to make mem R/W if the old void* val
                  in destination matches our new void* val*/
            if (*(LPVOID*)FirstThunk != pfnNew) {
            /* TODO refactor, this is inefficient, but is done only 1x per perl
               proc and doesn't UI lag. Guessing 100s us, or < 10 ms at max*/
              if (!WriteProcessMemory(hp,(LPVOID*)FirstThunk,&pfnNew,sizeof(pfnNew),NULL)
                && (ERROR_NOACCESS == GetLastError()))  {
                  DWORD dwOldProtect;
                  if (VirtualProtect((LPVOID)FirstThunk,sizeof(pfnNew),PAGE_WRITECOPY,&dwOldProtect)) {
                      if (!WriteProcessMemory(hp,(LPVOID*)FirstThunk,&pfnNew,sizeof(pfnNew),NULL))
                          S_croak_sub_glr_k32(cv, WriteProcessMemory);
                      if (!VirtualProtect((LPVOID)FirstThunk,sizeof(pfnNew),dwOldProtect,&dwOldProtect))
                          S_croak_sub_glr_k32(cv, VirtualProtect);
                  }
                  else
                      S_croak_sub_glr_k32(cv, VirtualProtect);
              }
            }
        }
    }
    return av;
}
#undef APPRVA2ABS

STATIC void
S_do_bootstrap_asserts(pTHX) {
    if(!EADmemNNEQsAorW("FormatMessageA", 14, "FormatMessage"))
      croak_nocontext("FormatMessageA");
    if(!EADmemNNEQsAorW("FormatMessageW", 14, "FormatMessage"))
      croak_nocontext("FormatMessageW");
    if(!EADmem2pNNEQs("GetProcAddress", STRLENs("GetProcAddress"), "GetProc","Address"))
      croak_nocontext("GetProcAddress 1p no nul");
    if(!EADmem2pEQs("GetProcAddress", STRLENs("GetProcAddress")+1, "GetProc","Address"))
      croak_nocontext("GetProcAddress 2p nul");
    if(!(AWLastCh("FormatMessageA", "FormatMessageA") == 'A'))
      croak_nocontext("FormatMessageA last ch %c", AWLastCh("FormatMessageA", "FormatMessageA"));
    if(!EADmemEQs("Az\0z", 3, "Az"))
      croak_nocontext("Az nul chk");
    if(!EADmem2pEQs("GetProcAddress\0zz", STRLENs("GetProcAddress")+1, "GetProc","Address"))
      croak_nocontext("GetProcAddress nul chk");
    if(memNE("GetProcAddress", K32FN2STR(GetProcAddress), sizeof("GetProcAddress")))
      croak_nocontext("FN2PV GPA");
    if(memNE("CreateFileW", K32FN2STR(CreateFileW), sizeof("CreateFileW")))
      croak_nocontext("FN2PV CFW");
}

MODULE = Win32::ExeAsDll		PACKAGE = Win32::ExeAsDll::HMODULE

PROTOTYPES: DISABLE

void
main(obj, cmdline=NULL, fileout=NULL, fileerr=NULL)
  SV* obj
  SV* cmdline
  SV* fileout
  SV* fileerr
PREINIT:
  SV* TmpRV;
  AV* av;
  SV** svp;
  SV* sv_dtor;
  XPVMG * SvBodyDtor;
  dMY_CXT;
  jmp_buf env;
  WCHAR warr[MAX_PATH];
  CHAR argv_pv_arr[MAX_PATH];
PPCODE:
    PUTBACK;
    TmpRV = obj;
    if( SvROK(TmpRV) && SvTYPE((TmpRV = SvRV(TmpRV))) == SVt_PVAV
        && SvSTASH(TmpRV) == MY_CXT.classHmod )
            av = (AV*)TmpRV;
    else
	    croak_xs_usage(cv, "obj, cmdline=NULL, fileout=NULL, fileerr=NULL");
    SvBodyDtor = MY_CXT.SvBodyDtor;
    if(!SvBodyDtor) {
        MAGIC * mg = sv_magicext( (sv_dtor = newSV_type_mortal(SVt_PVMG)), /* was SVt_PVLV */
                                  NULL,PERL_MAGIC_ext,(MGVTBL *)&vtbl_FreeMainInvkRsrcs,NULL,0);
        mg->mg_flags |= MGf_DUP;
        SvBodyDtor = SvANY(sv_dtor);
        /* SvHOUT(sv_dtor) = NULL;
        SvHERR(sv_dtor) = NULL;
        SvHHEAP(sv_dtor) = NULL; */
    }
    else {
        MY_CXT.SvBodyDtor = NULL;
        sv_dtor = sv_newmortal();
        SvANY(sv_dtor) = SvBodyDtor;
        SvFLAGS(sv_dtor) &= ~SVTYPEMASK;
        SvFLAGS(sv_dtor) |= SVt_PVMG;
        SvRMAGICAL_on(sv_dtor);
    }
    {
      HANDLE fileerr_h;
      if(fileerr)
          fileerr_h = CreateCapFile(aTHX_ cv, fileerr);
      else
          fileerr_h = NULL;
      MY_CXT.caperr = fileerr_h;
    }
    {
      HANDLE fileout_h;
      if(fileout)
          fileout_h = CreateCapFile(aTHX_ cv, fileout);
      else
          fileout_h = NULL;
      MY_CXT.capout = fileout_h;
    }
    svp = av_fetch_simple(av, AV_HMODS_START_IDX, 0);
    if(!svp || !SvIOK(*svp))
      croak_xs_usage(cv, "obj, cmdline=NULL, fileout=NULL, fileerr=NULL");
    MY_CXT.childExeHmod = (HMODULE)PTR2nat(SvIVX(*svp));
    if(cmdline) { /* This C stack buf must stay alive for the entire EXE main() call.
      Only with k32.dll APIs can we reuse/discard our buffers instantly
      after getting back a pre/hanlde from k32.dll. */
      int wargc;
      LPWSTR * wargv;
      Size_t LAlen;
      char * argv_pv;
      int argv_pv_left;
      WCHAR * wstr = warr;
      int wlen = (sizeof(warr)/2);
      Size_t off;
      char** argv_pv_start;
      int i;
      while((wlen = (int)sv_to_wstr_cstk(aTHX_ cv, cmdline, wstr, wlen)) < 0) {
          wlen = -wlen;
          wstr = (WCHAR*)alloca((wlen+4)*2);
      }
      MY_CXT.OneLineCmdLine = SvPVX(cmdline);
      MY_CXT.wOneLineCmdLine = wstr;
      wargv = CommandLineToArgvW(wstr, &wargc);
      if(!wargv)
          S_croak_sub_glr(cv, "CommandLineToArgvW");
      LAlen =  LocalSize((HLOCAL)wargv);
      argv_pv_start = (char**)alloca(LAlen);
      argv_pv_start = CopyD(wargv, argv_pv_start, LAlen, char);
      LocalFree((HLOCAL)wargv); /* copy to leak-proof C stk and release now, paranoia */
      off = PTR2nat(argv_pv_start)-PTR2nat(wargv);
      for(i=0; i < wargc; i++) { /* relative adj ptrs */
          argv_pv_start[i] = argv_pv_start[i]+off;
      }
      wargv = (LPWSTR *)argv_pv_start;
      MY_CXT.wargv = wargv;
      MY_CXT.wargc = wargc;
      argv_pv = argv_pv_arr;
      argv_pv_left = sizeof(argv_pv_arr);
      memset(argv_pv, 0xBB, argv_pv_left);
      /* will crash, UTF16 -> ANSI on 4/8 byte ptrs TODO */
      off = (wargc+1)*sizeof(void*); /* really void** byte len */
      if(off > sizeof(argv_pv_arr))
          argv_pv_start = (char**)alloca(off);
      else {
          argv_pv_start = (char**)argv_pv;
          argv_pv_left -= ((wargc+1)*sizeof(void*));
          argv_pv += ((wargc+1)*sizeof(void*));
      }
      argv_pv_left--; /* '\0' just in case */
      for(i=0; i < wargc; i++) {
          WCHAR* wstr = wargv[i];
          U32 wlen = (U32)wcslen(wstr); /* inc U16 L'\0', don't bother 4GB OF chk */
          int argv_pv_len;
          while((argv_pv_len = (int)wstr_to_pv_cstk(aTHX_ cv, wstr, wlen, argv_pv, argv_pv_left)) < 0) {
            argv_pv_len = -argv_pv_len;
            argv_pv_left = argv_pv_len;
            argv_pv = (char*)alloca(argv_pv_len+1);
          }
          argv_pv_start[i] = argv_pv;
          if(argv_pv_len < argv_pv_left) {
            argv_pv_left -= argv_pv_len;
            argv_pv += argv_pv_len;
          }
          else { /* need a alloca() now fast return by wstr_to_pv_cstk() */
            argv_pv_left = 0;
            argv_pv = NULL;
          }
      }
      argv_pv_start[i] = NULL;
      MY_CXT.argv = argv_pv_start;
    }
    else {
        DWORD l;
        HMODULE hModule = MY_CXT.childExeHmod;
        WCHAR * wstr = (WCHAR *)(PTR2nat(warr)+(sizeof(void*)*2));
        /* reserve 2 WCHARs for 2 '"' double quotes, one for [0], other at [end] */
        DWORD wlen = (sizeof(warr)-(sizeof(void*)*2)-(sizeof(WCHAR)*2))/2;
        /* write into buf starting at wstr[1], we fill in the '"' later */
        while((l = GetModuleFileNameW(hModule, &wstr[1], wlen)) && l >= wlen) {
            wlen = (wlen * 2);
            wstr = (WCHAR *)alloca((wlen+2) * 2); /* secret +2 for quotes */
        }
        if(!l)
            S_croak_sub_glr_k32(cv, GetModuleFileNameW);
        wstr[0] = L'"';
        wstr[++l] = L'"';
        wstr[++l] = L'\0';
        wlen = l;
        ((WCHAR **)(PTR2nat(warr)))[0] = wstr;
        ((WCHAR **)(PTR2nat(warr)))[1] = NULL;
        MY_CXT.wargv = (WCHAR **)(PTR2nat(warr));
        MY_CXT.wargc = 1;
        MY_CXT.wOneLineCmdLine = wstr;
        {
            char * argv_pv = (char*)(PTR2nat(argv_pv_arr)+(sizeof(void*)*2));
            int argv_pv_len  = sizeof(argv_pv_arr)-(sizeof(void*)*2);
            while((argv_pv_len = (int)wstr_to_pv_cstk(aTHX_ cv, wstr, wlen, argv_pv, argv_pv_len)) < 0) {
                argv_pv_len = -argv_pv_len;
                argv_pv = (char*)alloca(argv_pv_len+1);
            }
            ((char **)(PTR2nat(argv_pv_arr)))[0] = argv_pv;
            ((char **)(PTR2nat(argv_pv_arr)))[1] = NULL;
            MY_CXT.OneLineCmdLine = argv_pv;
            MY_CXT.argv = (char **)(PTR2nat(argv_pv_arr));
        }
    }
    MY_CXT.exitcode = 0;
    {
      HANDLE h = MY_CXT.HeapPool;
      ULONG ul;
      if(h) {
          MY_CXT.HeapPool = NULL;
          HeapDestroy(h);
      }
      h = HeapCreate(0,0,0); /* cmd.exe leaks 44KB each time */
      ul = HEAP_LFH;
      MY_CXT.HeapPool = h;
      HeapSetInformation(h, HeapCompatibilityInformation, &ul, sizeof(ul));
    }
    svp = av_fetch_simple(av, _GMA_IDX, 0);
    if(!svp || !SvIOK(*svp))
      croak_xs_usage(cv, "obj, cmdline=NULL, fileout=NULL, fileerr=NULL");
    MY_CXT.currentpfn__getmainargs = (__getmainargs_T)PTR2nat(SvIVX(*svp));
    svp = av_fetch_simple(av, _GETOSF_IDX, 0);
    if(!svp || !SvIOK(*svp))
      croak_xs_usage(cv, "obj, cmdline=NULL, fileout=NULL, fileerr=NULL");
    MY_CXT.currentpfn_get_osfhandle = (_get_osfhandle_T)PTR2nat(SvIVX(*svp));
    svp = av_fetch_simple(av, _QNM_IDX, 0);
    if(!svp || !SvIOK(*svp))
      croak_xs_usage(cv, "obj, cmdline=NULL, fileout=NULL, fileerr=NULL");
    MY_CXT.currentpfn_query_new_mode = (_query_new_mode_T)PTR2nat(SvIVX(*svp));
    svp = av_fetch_simple(av, _GETENV_IDX, 0);
    if(!svp || !SvIOK(*svp))
      croak_xs_usage(cv, "obj, cmdline=NULL, fileout=NULL, fileerr=NULL");
    MY_CXT.currentpfn_get_environ = (_get_environ_T)PTR2nat(SvIVX(*svp));
    MY_CXT.envp = (jmp_buf *)env;
    if(!setjmp(env)) {
        void (*f)();
        PHANDLER_ROUTINE HandlerRoutine = gPfnHandlerRoutine;
        if (HandlerRoutine) {
            gPfnHandlerRoutine = NULL;
            SetConsoleCtrlHandler(HandlerRoutine_hook, FALSE);
        }
        svp = av_fetch_simple(av, MAIN_IDX, 0);
        if(!svp || !SvIOK(*svp))
          croak_xs_usage(cv, "obj, cmdline=NULL, fileout=NULL, fileerr=NULL");
        /* Win32's ACTUAL main(), as defined by PE spec,
        not your MSVC or GCC compiler is " void __stdcall NoCRTMain(void) " */
        f = (void (*)())PTR2nat(SvIVX(*svp));
        f();
    }
    mg_free_ead(aTHX_ sv_dtor, NULL);
    if(1) {
        MY_CXT.SvBodyDtor = SvANY(sv_dtor);
        SvANY(sv_dtor) = NULL;
        SvFLAGS(sv_dtor) &= ~SVTYPEMASK;
        SvFLAGS(sv_dtor) |= SVt_NULL;
        SvRMAGICAL_off(sv_dtor);
    }
    {
      dXSTARG;
      SPAGAIN;
      PUSHs(TARG);
      PUTBACK;
      {
          int ret = MY_CXT.exitcode;
          MY_CXT.exitcode = 0;
          sv_setiv_mg(TARG, ret);
      }
    }
    return;

MODULE = Win32::ExeAsDll		PACKAGE = Win32::ExeAsDll

void
new(...)
PREINIT:
  AV* av;
  SV* sv_path;
CODE:

  if (items < 0 || items > 2) /* $class, aka ST(0) is unused here */
       croak_xs_usage(cv,  "[class[, path=\"" DEFAULT_EXE_A "\"]]");
  if (items < 2)
      sv_path = NULL;
  else
      sv_path = POPs;
  XSprePUSH;
  PUSHs(&PL_sv_undef);
  PUTBACK;

  av = LoadExe(aTHX_ cv, sv_path);
  if (av) {
    /* dXSTARG; Don't use, b/c obj's DESTROY is not called until the
       caller PP sub's CV* is freed in perl_destruct()/global destruction. */
    SV* retsv = sv_2mortal(newRV_noinc((SV*)av));
    dMY_CXT;
    SETs(retsv);
    sv_bless(retsv, MY_CXT.classHmod);
  }
  return;

void
DumpNtDllLdrTable(out=NULL)
  SV* out
PREINIT:
  SV* retrv;
  AV* av;
PPCODE:
  if(out && !SvREADONLY(out)) {
    if(SvROK(out)) {
      if(SvTYPE(SvRV(out)) <= SVt_PVLV)
        retrv = SvRV(out);
      else
        retrv = out;
    }
    else
      retrv = out;
  }
  else {
    U8 gm = GIMME_V;
    if(gm != G_VOID) {
      dXSTARG;
      retrv = TARG;
      PUSHs(TARG);
    }
    else
      retrv = out; /* stays NULL */
  }
  PUTBACK;
  if(!retrv)
      croak_xs_usage(cv, "out=NULL");
  av = newAV();
  sv_setrv_noinc(retrv, (SV*)av);
  {
      PTEB Teb = NtCurrentTeb();
      PPEB Peb = Teb->ProcessEnvironmentBlock;
      PPEB_LDR_DATA Ldr = Peb->Ldr;
      PLIST_ENTRY Entry = Ldr->InMemoryOrderModuleList.Flink;
      for (; Entry != &Ldr->InMemoryOrderModuleList; Entry = Entry->Flink) {
          SV* svFullDllName;
          SV* svBaseDllName;
          SV* svObsoleteLoadCount;
          SV* sv;
          AV* av2;
          PULONG pUL;
          PUSHORT pObsoleteLoadCount;
          PUNICODE_STRING ustr;
          PLDR_DATA_TABLE_ENTRY hMod =
              CONTAINING_RECORD(Entry, LDR_DATA_TABLE_ENTRY, InMemoryOrderLinks);
          if (hMod->DllBase == NULL)
              continue;
          av2 = newAV_alloc_xz(3);
          AvFILLp(av2) = 2;
          sv = newRV_noinc((SV*)av2);
          av_store_simple(av, AvFILLp(av)+1, sv);
          svFullDllName = newSV_type(SVt_PV);
          AvARRAY(av2)[0] = svFullDllName;
          ustr = &(hMod->FullDllName);
          svFullDllName = S_sv_setwstr(aTHX_ cv, svFullDllName, ustr->Buffer, ustr->Length / 2);
          svBaseDllName = newSV_type(SVt_PV);
          AvARRAY(av2)[1] = svBaseDllName;
          ustr++; /* UNICODE_STRING FullDllName; UNICODE_STRING BaseDllName; */
          svBaseDllName = S_sv_setwstr(aTHX_ cv, svBaseDllName, ustr->Buffer, ustr->Length / 2);
          ustr++;
          pUL = (PULONG)ustr;
          pUL++; /* WinNT 3.1 - Win 7 use USHORT ObsoleteLoadCount;
          but >= Win 8 supposedly "retired" this field and have a brand new
          32-bit size, type DWORD, DLL load ref count C struct member
          somewhere much much further down in the PEB struxt.  I didn't
          test this module on Win 8/Win 10 to know what legacy field
          USHORT ObsoleteLoadCount; holds on Win 8/10/11. */
          pObsoleteLoadCount = (PUSHORT)pUL;
          svObsoleteLoadCount = newSVuv(*pObsoleteLoadCount);
          AvARRAY(av2)[2] = svObsoleteLoadCount;
      }
  }
  return;

MODULE = Win32::ExeAsDll		PACKAGE = Win32::ExeAsDll::HMODULE

void
DESTROY(obj)
  SV* obj
ALIAS:
  DESTROY = DUMMY_ALIAS_IX
PREINIT:
  SV* TmpRV;
  AV* av;
  U32 i;
  U32 len;
  SV** svp;
  dMY_CXT;
PPCODE:
    PUTBACK;
    TmpRV = obj;
    if( SvROK(TmpRV) && SvTYPE((TmpRV = SvRV(TmpRV))) == SVt_PVAV
        && SvSTASH(TmpRV) == MY_CXT.classHmod )
            av = (AV*)TmpRV;
    else
	    croak_xs_usage(cv, "obj");
    len = (U32)AvFILLp(av)+1;
    for(i = AV_HMODS_START_IDX; i<len; i++) {
      svp = av_fetch_simple(av, i, 0);
      if(*svp && SvIOK(*svp)) {
          if(!FreeLibrary(NUM2PTR(HMODULE,SvIVX(*svp))))
            S_croak_sub_glr_k32(cv, FreeLibrary);
      }
    }
    return;

#undef dVAR
#define dVAR dXSTARG

SV*
GetExeFileName(obj)
    SV* obj;
PREINIT:
    SV* TmpRV;
    AV* av;
    SV** svp;
    dMY_CXT;
CODE:
    SETs(TARG);
    TmpRV = obj;
    if( SvROK(TmpRV) && SvTYPE((TmpRV = SvRV(TmpRV))) == SVt_PVAV
        && SvSTASH(TmpRV) == MY_CXT.classHmod )
            av = (AV*)TmpRV;
    else
	    croak_xs_usage(cv, "obj");
    svp = av_fetch_simple(av, AV_HMODS_START_IDX, 0);
    if(!svp || !SvIOK(*svp))
      croak_xs_usage(cv, "obj");
    {
        HMODULE hModule = (HMODULE)PTR2nat(SvIVX(*svp));
        WCHAR warr[MAX_PATH];
        WCHAR * wstr = (WCHAR *)(PTR2nat(warr));
        DWORD wlen = (sizeof(warr))/2;
        DWORD l;
        while((l = GetModuleFileNameW(hModule, wstr, wlen)) && l >= wlen) {
            wlen = (wlen * 2);
            wstr = (WCHAR *)alloca(wlen * 2);
        }
        if(!l)
            sv_setpv_mg(TARG, NULL);
        else {
            RETVAL = S_sv_setwstr(aTHX_ cv, TARG, wstr, l);
            SvSETMAGIC(RETVAL);
        }
    }
    return;

#undef dVAR
#define dVAR dNOOP

MODULE = Win32::ExeAsDll		PACKAGE = Win32::ExeAsDll

#ifdef PERL_IMPLICIT_CONTEXT

void
CLONE(...)
PPCODE:
    PUTBACK; /* some vars go out of scope now in machine code */
    {
#define memcpy(a,b,c) (a,b,c)
        MY_CXT_CLONE;
#undef memcpy
        Zero(&(MY_CXT), 1, MY_CXT);
        /* get the SVs for this interp, not the parent interp*/
        if (0) {
            GV* gv;
            HV* cvstash;
            HV* gvstash;
            HV* stash =
                ((cvstash = CvSTASH(cv)) && CvNAMED(cv))
                ? cvstash
                :   (((gv = CvGV(cv)) && isGV(gv) && (gvstash = GvSTASH(gv)))
                    ?  gvstash
                    : cvstash);
            GV** gvp = (GV**)hv_fetchs(stash, "HMODULE::", FALSE);
            gv = *gvp;
            stash = GvHV(gv);
            MY_CXT.classHmod = stash;
            sv_dump((SV*)stash);
            MY_CXT.CSHV = newHV();
        }
        else
            initMyCxt(aTHX_ aMY_CXT);
    }
    return; /* dont execute another implied XSPP PUTBACK */

void
END(...)
CODE:
    if(PL_perl_destruct_level > 0) {
        dMY_CXT;
        HANDLE h = MY_CXT.ThreadHandleCache.hThread;
        if(h) {
            MY_CXT.ThreadHandleCache.hThread = NULL;
            CloseHandle(h);
        }
        mg_free_ead(aTHX_ NULL, NULL);
    }
    /* skip implicit PUTBACK, returning @_ to caller, more efficient*/
    return;

#endif


#undef dVAR
#define dVAR BOOL retProcAttach = InitOnProcessAttach(); CV* bootcv = cv; CV* newcv 
#undef DUMMY_ALIAS_IX
#define DUMMY_ALIAS_IX ((newcv = cv),XSANY.any_i32)

BOOT:
{
    PERL_UNUSED_VAR(retProcAttach);
#if !defined(newXS_deffile) && PERL_VERSION_LE(5, 21, 5)
#   define newXS_deffile(a,b) Perl_newXS(aTHX_ a,b,file)
#endif
#ifdef USE_ITHREADS
    newXS_deffile("Win32::ExeAsDll::HMODULE::CLONE_SKIP", BulkTools_XS_CLONE_SKIP);
#endif
    newXS_deffile("Win32::ExeAsDll::AreFileApisANSI", BulkTools_XS_AreFileApisANSI);
    if(ISDEV_EXPR) {
        GV* gv;
        HV* cvstash;
        HV* gvstash; /* cv happens to be XSUB Win32::ExeAsDll::HMODULE::DESTROY rn */
        HV* stash =
            ((cvstash = CvSTASH(bootcv)) && CvNAMED(bootcv))
            ? cvstash
            :   (((gv = CvGV(bootcv)) && isGV(gv) && (gvstash = GvSTASH(gv)))
                ?  gvstash
                : cvstash);
       newCONSTSUB_flags(stash, "AV_HMODS_START_IDX", STRLENs("AV_HMODS_START_IDX"), 0, newSViv(AV_HMODS_START_IDX));
    }
    {
        MY_CXT_INIT;
        /* Zero(&MY_CXT, 1, MY_CXT); redundant, MY_CXT_INIT does it */
        if(1)
            initMyCxt(aTHX_ aMY_CXT);
        else {
            /* HV* stash = gv_stashpvs("Win32::ExeAsDll::HMODULE", GV_ADD); */
            GV* gv;
            HV* cvstash;
            HV* gvstash; /* cv happens to be XSUB Win32::ExeAsDll::HMODULE::DESTROY rn */
            CV* cv = newcv;
            HV* stash =
                ((cvstash = CvSTASH(cv)) && CvNAMED(cv))
                ? cvstash
                :   (((gv = CvGV(cv)) && isGV(gv) && (gvstash = GvSTASH(gv)))
                    ?  gvstash
                    : cvstash);
            MY_CXT.classHmod = stash;
            MY_CXT.CSHV = newHV();
        }
    }
#ifdef ISDEV
    S_do_bootstrap_asserts(aTHX);
#endif
}

