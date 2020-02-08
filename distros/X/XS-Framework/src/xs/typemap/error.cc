#include "error.h"

namespace xs {

PERL_THREAD_LOCAL HV* Typemap<std::error_code>::stash  = gv_stashpvs("XS::STL::ErrorCode", GV_ADD);
PERL_THREAD_LOCAL HV* Typemap<panda::ErrorCode>::stash = gv_stashpvs("XS::ErrorCode", GV_ADD);

}
