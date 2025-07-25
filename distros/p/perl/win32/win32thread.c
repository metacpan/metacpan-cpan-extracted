#include "EXTERN.h"
#include "perl.h"

#ifdef USE_DECLSPEC_THREAD
__declspec(thread) void *PL_current_context = NULL;
#endif

void
Perl_set_context(void *t)
{
#if defined(USE_ITHREADS)
#  ifdef USE_DECLSPEC_THREAD
    Perl_current_context = t;
    PERL_SET_NON_tTHX_CONTEXT(t);
#  else
    DWORD err = GetLastError();
    TlsSetValue(PL_thr_key,t);
    SetLastError(err);
#  endif
    dTHXa(t);
    PL_sys_intern.cur_tid = GetCurrentThreadId();
#endif
}

void *
Perl_get_context(void)
{
#if defined(USE_ITHREADS)
#  ifdef USE_DECLSPEC_THREAD
    return Perl_current_context;
#  else
    DWORD err = GetLastError();
    void *result = TlsGetValue(PL_thr_key);
    SetLastError(err);
    return result;
#  endif
#else
    return NULL;
#endif
}
