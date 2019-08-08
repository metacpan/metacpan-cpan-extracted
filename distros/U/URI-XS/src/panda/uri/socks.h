#pragma once
#include <panda/uri/Strict.h>

namespace panda { namespace uri {

class URI::socks : public UserPass {
public:
    socks () : Strict() {}
    socks (const string& source, int flags = 0) : Strict(source, flags) { strict_scheme(); }
    socks (const URI& source)                   : Strict(source)        { strict_scheme(); }
};

}}
