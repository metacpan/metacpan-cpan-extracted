#pragma once
#include <xs.h>
#include <panda/unievent/AddrInfo.h>

namespace xs {

template <> struct Typemap<panda::unievent::AddrInfoHints> : TypemapBase<panda::unievent::AddrInfoHints> {
    using Hints = panda::unievent::AddrInfoHints;

    static Hints in (SV* arg);

    static Sv create (const Hints& var, Sv = Sv()) {
        return Simple(panda::string_view(reinterpret_cast<const char*>(&var), sizeof(Hints)));
    }
};

}
