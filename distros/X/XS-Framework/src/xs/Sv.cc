#include "Sv.h"
#include "Sub.h"
#include "Simple.h"
#include <ostream>

namespace xs {

static Sv::payload_marker_t _default_marker;
Sv::payload_marker_t* Sv::default_marker() { return &_default_marker; }

const Sv Sv::undef(&PL_sv_undef);
const Sv Sv::yes(&PL_sv_yes);
const Sv Sv::no(&PL_sv_no);

MAGIC* Sv::payload_attach (void* ptr, SV* obj, const payload_marker_t* marker) {
    upgrade(SVt_PVMG);
    MAGIC* mg;
    Newx(mg, 1, MAGIC);
    mg->mg_moremagic = SvMAGIC(sv);
    SvMAGIC_set(sv, mg);
    mg->mg_virtual = const_cast<payload_marker_t*>(marker);
    mg->mg_type = PERL_MAGIC_ext;
    mg->mg_len = 0;
    mg->mg_ptr = (char*)ptr;
    mg->mg_private = 0;

    if (obj) {
        mg->mg_obj = SvREFCNT_inc_simple_NN(obj);
        mg->mg_flags = MGf_REFCOUNTED;
    } else {
        mg->mg_obj = NULL;
        mg->mg_flags = 0;
    }

    #ifdef USE_ITHREADS
      if (marker->svt_dup) mg->mg_flags |= MGf_DUP;
    #endif

    return mg;
}

void Sv::__at_perl_destroy () {
    const_cast<Sv*>(&undef)->reset();
    const_cast<Sv*>(&yes)->reset();
    const_cast<Sv*>(&no)->reset();
}

std::ostream& operator<< (std::ostream& os, const Sv& sv) {
    SV* v = sv;
    if (!v) return os << (void*)nullptr;
    switch (sv.type()) {
        case SVt_NULL: return os << "<undef>";
        case SVt_PVAV: return os << "array(" << (void*)v << ')';
        case SVt_PVHV: return os << "hash(" << (void*)v << ')';
        case SVt_PVFM: return os << "format(" << (void*)v << ')';
        default:
            STRLEN len;
            auto s = SvPV(v, len);
            return os.write(s, len);
    }
}

}
