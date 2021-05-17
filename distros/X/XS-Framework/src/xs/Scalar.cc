#include <xs/Scalar.h>

namespace xs {

const Scalar Scalar::undef(&PL_sv_undef);
const Scalar Scalar::yes(&PL_sv_yes);
const Scalar Scalar::no(&PL_sv_no);

void Scalar::_validate_rest() {
    if (SvTYPE(sv) != SVt_PVLV) {
        reset();
        throw std::invalid_argument("SV is not a scalar value");
    }
    auto newval = newSVsv(sv);
    reset();     // remove old sv
    sv = newval; // newSVsv creates sv with refcnt=1, so no inc is required
}

void Scalar::__at_perl_destroy () {
    const_cast<Scalar*>(&undef)->reset();
    const_cast<Scalar*>(&yes)->reset();
    const_cast<Scalar*>(&no)->reset();
}

}
