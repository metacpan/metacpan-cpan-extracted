#pragma once
#include "defs.h"
#include "../hash.h"

namespace std {
    template<>
    struct hash<panda::string_view> {
        size_t operator() (panda::string_view v) const {
            return panda::hash::hashXX<size_t>(v);
        }
    };

    template<>
    struct hash<panda::u16string_view> {
        size_t operator() (panda::u16string_view v) const {
            return panda::hash::hashXX<size_t>(panda::string_view((const char*)v.data(), v.length() * sizeof(char16_t)));
        }
    };

    template<>
    struct hash<panda::u32string_view> {
        size_t operator() (panda::u32string_view v) const {
            return panda::hash::hashXX<size_t>(panda::string_view((const char*)v.data(), v.length() * sizeof(char32_t)));
        }
    };

    template<>
    struct hash<panda::wstring_view> {
        size_t operator() (panda::wstring_view v) const {
            return panda::hash::hashXX<size_t>(panda::string_view((const char*)v.data(), v.length() * sizeof(wchar_t)));
        }
    };
}
