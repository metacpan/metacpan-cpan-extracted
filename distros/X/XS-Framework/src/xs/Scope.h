#pragma once
#include "Hash.h"
#include <panda/string_view.h>

#ifndef REFCOUNTED_HE_EXISTS
    #define REFCOUNTED_HE_EXISTS 0x00000002
#endif

namespace xs {

using xs::my_perl;

struct Scope {
    struct Hints {
        static void set    (panda::string_view name, const Sv& value);
        static void remove (panda::string_view name);

        static bool exists (panda::string_view name) {
            return cop_hints_fetch_pvn(PL_curcop, name.data(), name.length(), 0, REFCOUNTED_HE_EXISTS);
        }

        static Scalar get (panda::string_view name) {
            return cop_hints_fetch_pvn(PL_curcop, name.data(), name.length(), 0, 0);
        }

        static Hash get ();

        static Scalar get_ct (panda::string_view name);
    };
};

}
