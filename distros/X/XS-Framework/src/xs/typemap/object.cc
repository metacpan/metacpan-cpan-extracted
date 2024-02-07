#include "object.h"
#include <cxxabi.h>
#include "error.h"

namespace xs { namespace typemap { namespace object {

using destroy_hook_t = bool(*)(pTHX_ SV*);

CV*        fake_dtor;
svt_copy_t backref_marker;

static destroy_hook_t orig_destroy_hook;

static int _backref_marker (pTHX_ SV*, MAGIC*, SV*, const char*, I32) { assert(0); return 0; } // should not be called

static bool destroy_hook (pTHX_ SV* sv) {
    MAGIC* mg = SvMAGIC(sv);
    for (; mg; mg = mg->mg_moremagic) {
        if (mg->mg_virtual && (mg->mg_flags & MGf_COPY) && (mg->mg_virtual->svt_copy == backref_marker)) {
            if ((mg->mg_flags & MGf_LOCAL) && mg->mg_virtual->svt_local(aTHX_ sv, mg)) return TRUE;
        }
    }
    if (orig_destroy_hook) return orig_destroy_hook(aTHX_ sv);
    return TRUE;
}

void init () {
    Stash stash("XS::Framework", GV_ADD);

    fake_dtor      = newCONSTSUB(stash, "__FAKE_DTOR", newSViv(0));
    backref_marker = &_backref_marker;

    if (PL_destroyhook != &Perl_sv_destroyable) orig_destroy_hook = PL_destroyhook;
    PL_destroyhook = destroy_hook; // needed for correct operation of Typemap Storage MG with Backref feature enabled
}

panda::string type_details(const std::type_info& ti) {
    int status;
    panda::string r;
    char* class_name = abi::__cxa_demangle(ti.name(), nullptr, nullptr, &status);
    if (status != 0) {
        r += "[abi::__cxa_demangle error] ";
        r += ti.name();
    }
    else {
        r += class_name;
        free(class_name);
    }
    return r;
}

[[ noreturn ]] void _throw_no_package (const std::type_info& ti) {
    panda::string exc("no default perl class defined for typemap '");
    exc += type_details(ti);
    exc += "', either define it or explicitly bless PROTO on output";
    throw panda::exception(exc);
}

[[ noreturn ]] void _throw_incorrect_arg(SV* arg, const std::type_info& expected, panda::string_view package) {
    //"arg is an incorrect or corrupted object";
    panda::string arg_type;
    if (!arg) { arg_type = "NULL"; }
    else {
        Sv sv{arg};
        if (!sv.is_object() && !sv.is_object_ref()) {
            arg_type = "not an object";
        }
        else {
            Object obj(sv);
            arg_type = obj.stash().name();
        }
    }
    panda::string ex_details = "cannot convert arg '";
    ex_details += arg_type;
    ex_details += "' to expected '";
    ex_details += package;
    ex_details += "' (C++ type '" + type_details(expected) + "')";
    throw ex_details;
}

}}}

