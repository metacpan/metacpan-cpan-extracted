#pragma once
#include <panda/uri/Strict.h>

namespace panda { namespace uri {

struct URI::socks : Strict<URI::socks> {
    using Strict<URI::socks>::Strict;

    static string default_scheme () { return "socks5"; }
};

}}
