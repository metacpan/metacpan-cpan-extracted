#include "object.h"
#include <cxxabi.h>

namespace xs { namespace typemap { namespace object {

using destroy_hook_t = bool(*)(pTHX_ SV*);

CV*        fake_dtor;
svt_copy_t backref_marker;

static destroy_hook_t orig_destroy_hook;

static int _backref_marker (pTHX_ SV*, MAGIC*, SV*, const char*, I32) { assert(0); return 0; } // should not be called

static bool destroy_hook (pTHX_ SV* sv) {
    MAGIC* mg = SvMAGIC(sv);
    for (; mg; mg = mg->mg_moremagic) {
        if (mg->mg_virtual && mg->mg_virtual->svt_copy == backref_marker) {
            if (mg->mg_virtual->svt_local(aTHX_ sv, mg)) return TRUE;
        }
    }
    if (orig_destroy_hook) return orig_destroy_hook(aTHX_ sv);
    return TRUE;
}

void init (pTHX) {
    Stash stash("XS::Framework", GV_ADD);

    fake_dtor      = newCONSTSUB(stash, "__FAKE_DTOR", newSViv(0));
    backref_marker = &_backref_marker;

    if (PL_destroyhook != &Perl_sv_destroyable) orig_destroy_hook = PL_destroyhook;
    PL_destroyhook = destroy_hook; // needed for correct operation of Typemap Storage MG with Backref feature enabled
}

void _throw_no_package (const std::type_info& ti) {
    panda::string exc("no default perl class defined for typemap '");

    int status;
    char* class_name = abi::__cxa_demangle(ti.name(), nullptr, nullptr, &status);
    if (status != 0) exc += "[abi::__cxa_demangle error]";
    else {
        exc += class_name;
        free(class_name);
    }

    exc += "', either define it or explicitly bless PROTO on output";
    throw exc;
}

}}}
