#include "fn.h"
#include <panda/exception.h>

namespace panda { namespace backtrace {
volatile int fn_val = 0;

int fn01() {
    throw exception("...");
}
}}
