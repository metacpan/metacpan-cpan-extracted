#include <xs/Object.h>
#include <xs/Stash.h>

namespace xs {

void Object::stash (const Stash& stash) {
    auto old = SvSTASH(sv);
    SvSTASH_set(sv, (HV*)SvREFCNT_inc_simple(stash.get()));
    SvREFCNT_dec(old);
}

Sub Object::method        (const Sv& name)                 const { return stash().method(name); }
Sub Object::method        (const panda::string_view& name) const { return stash().method(name); }
Sub Object::method_strict (const Sv& name)                 const { return stash().method_strict(name); }
Sub Object::method_strict (const panda::string_view& name) const { return stash().method_strict(name); }

void Object::rebless (const Stash& stash) {
    _check_ref();
    sv_bless(_ref, stash);
}

}
