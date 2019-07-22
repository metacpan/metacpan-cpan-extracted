#pragma once
#include "base.h"
#include "../Simple.h"
#include <string>
#include <panda/string.h>
#include <panda/string_view.h>

namespace xs {

template <> struct Typemap<panda::string> : TypemapBase<panda::string> {
    static inline panda::string in (pTHX_ SV* arg) {
        STRLEN len;
        const char* data = SvPV_nomg(arg, len);
        return panda::string(data, len);
    }
    static inline Sv out (pTHX_ const panda::string& str, const Sv& = Sv()) { return Simple(str); }
};

template <> struct Typemap<std::string> : TypemapBase<std::string> {
    static inline std::string in (pTHX_ SV* arg) {
        STRLEN len;
        const char* data = SvPV_nomg(arg, len);
        return std::string(data, len);
    }
    static inline Sv out (pTHX_ const std::string& str, const Sv& = Sv()) { return Simple(panda::string_view(str.data(), str.length())); }
};

template <> struct Typemap<panda::string_view> : TypemapBase<panda::string_view> {
    static inline panda::string_view in (pTHX_ SV* arg) {
        STRLEN len;
        const char* data = SvPV_nomg(arg, len);
        return panda::string_view(data, len);
    }
    static inline Sv out (pTHX_ const panda::string_view& str, const Sv& = Sv()) { return Simple(str); }
};

}
