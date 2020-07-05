#include <xsheader.h>
#include <panda/exception.h>

using namespace panda;

MODULE = MyTest                PACKAGE = MyTest
PROTOTYPES: DISABLE

size_t call_dump_trace() {
    RETVAL = Backtrace().get_backtrace_info()->frames.size();
}
