#pragma once
#include "Hash.h"
#include <panda/string_view.h>

namespace xs {

using xs::my_perl;

struct Scope {
    struct Hints {
        static void set    (panda::string_view name, const Sv& value);
        static void remove (panda::string_view name);

        static bool exists (panda::string_view name) {
            #if PERL_VERSION >= 34
                return cop_hints_exists_pvn(PL_curcop, name.data(), name.length(), 0, 0);
            #else
                #ifndef REFCOUNTED_HE_EXISTS
                    #define REFCOUNTED_HE_EXISTS 0x00000002
                #endif
                return cop_hints_fetch_pvn(PL_curcop, name.data(), name.length(), 0, REFCOUNTED_HE_EXISTS);
            #endif
        }

        static Scalar get (panda::string_view name) {
            return cop_hints_fetch_pvn(PL_curcop, name.data(), name.length(), 0, 0);
        }

        static Hash get ();

        static Scalar get_ct (panda::string_view name);
    };
};

}
