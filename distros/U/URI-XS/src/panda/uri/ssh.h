#pragma once
#include <panda/uri/Strict.h>

namespace panda { namespace uri {

struct URI::ssh : Strict<URI::ssh> {
    using Strict<URI::ssh>::Strict;

    static string default_scheme () { return "ssh"; }
};

}}
