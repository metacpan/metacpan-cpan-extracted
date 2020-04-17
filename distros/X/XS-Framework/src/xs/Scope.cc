#include "Scope.h"
#include "Simple.h"

namespace xs {

using panda::string_view;

void Scope::Hints::set (string_view name, const Sv& value) {
    auto copy = Sv::create();
    sv_setsv(copy, value);

    auto hv = GvHV(PL_hintgv);
    auto he = hv_store_ent(hv, Simple(name), copy.detach(), 0);
    PL_hints |= HINT_LOCALIZE_HH;

    if (he) SvSETMAGIC(HeVAL(he));
}

void Scope::Hints::remove (string_view name) {
    PL_hints |= HINT_LOCALIZE_HH;
    Hash hints = GvHV(PL_hintgv);
    hints.erase(name);
}

Hash Scope::Hints::get () {
    return Hash::noinc(cop_hints_2hv(PL_curcop, 0));
}

Scalar Scope::Hints::get_ct (string_view name) {
    Hash hints = GvHV(PL_hintgv);
    return hints[name];
}

}
