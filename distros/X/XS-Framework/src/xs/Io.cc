#include <xs/Io.h>

namespace xs {

void Io::_validate () {
    if (!sv) return;
    if (SvTYPE(sv) == SVt_PVIO) return;
    if (SvTYPE(sv) == SVt_PVGV && GvIOp(sv)) {
        Sv::operator=(GvIOp(sv));
        return;
    }

    if (SvROK(sv)) {
        SV* val = SvRV(sv);
        if (SvTYPE(val) == SVt_PVIO) {
            Sv::operator=(val);
            return;
        }
        if (SvTYPE(val) == SVt_PVGV && GvIOp(val)) {
            Sv::operator=(GvIOp(val));
            return;
        }
    }

    if (is_undef()) return reset();
    reset();
    throw std::invalid_argument("SV is neither IO or IO reference, nor Glob or Glob reference with IO slot set");
}

}
