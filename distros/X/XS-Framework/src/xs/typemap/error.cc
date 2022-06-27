#include "error.h"

namespace xs {

HV* xs::Typemap<std::error_code>::stash() {
    static PERL_ITHREADS_LOCAL HV* hv = gv_stashpvs("XS::STL::ErrorCode", GV_ADD);
    return hv;
}

}
