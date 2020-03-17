#pragma once

#include <panda/string.h>

#if defined(__linux__)

#include <cstdio>
#include <cstdlib>

#include <execinfo.h>

namespace panda { namespace unievent { namespace debug {


// see https://www.gnu.org/software/libc/manual/html_node/Backtraces.html
inline panda::string get_trace() {
    void *array[10];
    size_t size;
    char **strings;

    panda::string result;

    size = backtrace(array, 10);
    strings = backtrace_symbols(array, size);

    for(size_t i = 0; i < size; i++) {
        result += strings[i];
        result += "\n";
    }

    free(strings);
    return result;
}

}}}

#else

namespace panda { namespace unievent { namespace debug {

inline panda::string get_trace() {}

}}}

#endif



