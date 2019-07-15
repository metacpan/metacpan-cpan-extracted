#include <xs/Simple.h>

namespace xs {

const Simple Simple::undef(&PL_sv_undef);
const Simple Simple::yes(&PL_sv_yes);
const Simple Simple::no(&PL_sv_no);

Simple Simple::format (const char*const pat, ...) {
    va_list args;
    va_start(args, pat);
    SV* sv = vnewSVpvf(pat, &args);
    va_end(args);
    return Simple::noinc(sv);
}

U32 Simple::hash () const {
    if (sv) {
        if (SvIsCOW_shared_hash(sv)) return SvSHARED_HASH(sv);
        U32 h; STRLEN len;
        const char* buf = SvPV_nomg(sv, len);
        PERL_HASH(h, buf, len);
        return h;
    } else return 0;
}

void Simple::__at_perl_destroy () {
    const_cast<Simple*>(&undef)->reset();
    const_cast<Simple*>(&yes)->reset();
    const_cast<Simple*>(&no)->reset();
}

}
