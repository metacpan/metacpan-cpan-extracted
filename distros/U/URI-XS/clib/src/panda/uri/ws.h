#pragma once
#include <panda/uri/Strict.h>

namespace panda { namespace uri {

struct URI::wss : Strict<URI::wss> {
    using Strict<URI::wss>::Strict;

    static string default_scheme () { return "wss"; }
};

struct URI::ws : Strict<URI::ws, URI::wss> {
    using Strict<URI::ws, URI::wss>::Strict;

    static string default_scheme () { return "ws"; }
};

}}
