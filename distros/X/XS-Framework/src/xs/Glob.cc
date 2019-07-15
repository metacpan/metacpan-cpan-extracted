#include <xs/Ref.h>
#include <xs/Glob.h>
#include <xs/Stash.h>
#include <xs/Simple.h>

namespace xs {

Glob Glob::create (const Stash& stash, std::string_view name, U32 flags) {
    GV* gv = (GV*)newSV(0);
    gv_init_pvn(gv, stash, name.data(), name.length(), flags);
    return gv;
}

Stash Glob::stash           () const { return GvSTASH((GV*)sv); }
Stash Glob::effective_stash () const { return GvESTASH((GV*)sv); }

static inline void _set_slot (SV** where, SV* what) {
    auto old = *where;
    *where = what;
    SvREFCNT_inc_simple_void(what);
    SvREFCNT_dec(old);
}

static inline void _set_slot (GV* where, CV* what) {
    auto old = GvCV(where);
    GvCV_set(where, what);
    SvREFCNT_inc_simple_void(what);
    SvREFCNT_dec(old);
}

void Glob::slot (SV* val) {
    GV* gv = (GV*)sv;
    if (!val || SvTYPE(val) <= SVt_PVMG) _set_slot(&GvSV(gv), val);
    else switch (SvTYPE(val)) {
        case SVt_PVCV: _set_slot(gv, (CV*)val); break;
        case SVt_PVHV: _set_slot((SV**)&GvHV(gv), val); break;
        case SVt_PVAV: _set_slot((SV**)&GvAV(gv), val); break;
        default: throw std::invalid_argument("can set unsupported type to a typeglob");
    }
}

void Glob::slot (AV* val)           { _set_slot((SV**)&GvAV((GV*)sv), (SV*)val); }
void Glob::slot (HV* val)           { _set_slot((SV**)&GvHV((GV*)sv), (SV*)val); }
void Glob::slot (CV* val)           { _set_slot((GV*)sv, val); }
void Glob::slot (const Scalar& val) { _set_slot(&GvSV((GV*)sv), val); }

}
