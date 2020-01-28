#include "error.h"

namespace xs {

thread_local Stash Typemap<std::error_code>::stash("XS::STL::ErrorCode", GV_ADD);
thread_local Stash Typemap<panda::ErrorCode>::stash("XS::ErrorCode", GV_ADD);

}
