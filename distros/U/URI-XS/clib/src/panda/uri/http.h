#pragma once
#include <panda/uri/Strict.h>

namespace panda { namespace uri {

struct URI::https : Strict<URI::https> {
    using Strict = Strict<URI::https>;
    using Strict::Strict;

    static string default_scheme () { return "https"; }
};

struct URI::http : Strict<URI::http, URI::https> {
    using Strict = Strict<URI::http, URI::https>;
    using Strict::Strict;

    static string default_scheme () { return "http"; }
};

}}
