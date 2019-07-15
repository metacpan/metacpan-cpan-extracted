#include <xs/Scalar.h>

namespace xs {

const Scalar Scalar::undef(&PL_sv_undef);
const Scalar Scalar::yes(&PL_sv_yes);
const Scalar Scalar::no(&PL_sv_no);

void Scalar::__at_perl_destroy () {
    const_cast<Scalar*>(&undef)->reset();
    const_cast<Scalar*>(&yes)->reset();
    const_cast<Scalar*>(&no)->reset();
}

}
