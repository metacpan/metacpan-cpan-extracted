
extern "C" {
#define PERL_NO_GET_CONTEXT /* we want efficiency! */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

void
call_func (pTHX_ void (*subaddr) (pTHX_ CV *), CV *cv, SV **mark)
{
    dSP;
    PUSHMARK(mark);
    (*subaddr)(aTHX_ cv);
    PUTBACK;
}

// yes, this macro should use XS() - but that inserts an unnecessary
// extern "C"
#define CALL_BOOT(name) \
    { \
        void name(register PerlInterpreter* my_perl , CV* cv);\
        call_func(aTHX_ name, cv, mark); \
    }

}

#include "tbb.h"

//typedef void (*boot_func) (pTHX_ CV*);

//extern boot_func boot_threads__tbb__init;

MODULE = threads::tbb		PACKAGE = threads::tbb

PROTOTYPES: DISABLE

BOOT:
    CALL_BOOT (boot_threads__tbb__init);
    CALL_BOOT (boot_threads__tbb__blocked_int);
    CALL_BOOT (boot_threads__tbb__concurrent__array);
    CALL_BOOT (boot_threads__tbb__concurrent__item);
    CALL_BOOT (boot_threads__tbb__concurrent__hash);
    CALL_BOOT (boot_threads__tbb__for_int_array_func);
    CALL_BOOT (boot_threads__tbb__for_int_method);
    CALL_BOOT (boot_threads__tbb__refcounter);
