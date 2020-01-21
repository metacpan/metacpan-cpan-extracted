#pragma once
#include <panda/uri/Strict.h>

namespace panda { namespace uri {

struct URI::telnet : Strict<URI::telnet> {
    using Strict<URI::telnet>::Strict;

    static string default_scheme () { return "telnet"; }
};

}}
