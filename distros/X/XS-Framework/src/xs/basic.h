#pragma once
#include <xsheader.h>
#include <panda/function.h>

#ifdef USE_ITHREADS
    #define PERL_THREAD_LOCAL thread_local
#else
    #define PERL_THREAD_LOCAL
#endif

#define XS_BOOT(mod)                        \
    void boot_ ## mod (pTHX_ CV*);          \
    xs::__boot_module(#mod, &boot_ ## mod, XS_VERSION, __FILE__);

namespace xs {

struct my_perl_auto_t { // per-thread interpreter to help dealing with pTHX/aTHX, especially for static initialization
  #ifdef PERL_IMPLICIT_CONTEXT
    static PerlInterpreter* main_interp;
    operator PerlInterpreter*   () const { return main_interp ? main_interp : PERL_GET_THX; }
    PerlInterpreter* operator-> () const { return main_interp ? main_interp : PERL_GET_THX; }
  #endif
};
extern my_perl_auto_t my_perl;

void at_perl_destroy (const panda::function<void()>& f);

void __call_at_perl_destroy  ();
void __call_at_thread_create ();

void __boot_module (const char* mod, void (*bootfunc)(pTHX_ CV*), const char* version, const char* file);

}
