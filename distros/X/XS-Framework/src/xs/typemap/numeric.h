#pragma once
#include "base.h"
#include "../Simple.h" // for _getnum()

namespace xs {

template <class TYPE> struct TypemapNumeric : TypemapBase<TYPE> {
    static inline TYPE in  (pTHX_ SV* arg)                    { return detail::_getnum<TYPE>(arg); }
    static inline Sv   out (pTHX_ TYPE var, const Sv& = Sv()) { return Simple(var); }
};

template <> struct Typemap<char>                : TypemapNumeric<char>               {};
template <> struct Typemap<short>               : TypemapNumeric<short>              {};
template <> struct Typemap<int>                 : TypemapNumeric<int>                {};
template <> struct Typemap<long>                : TypemapNumeric<long>               {};
template <> struct Typemap<long long>           : TypemapNumeric<long long>          {};
template <> struct Typemap<unsigned char>       : TypemapNumeric<unsigned char>      {};
template <> struct Typemap<unsigned short>      : TypemapNumeric<unsigned short>     {};
template <> struct Typemap<unsigned>            : TypemapNumeric<unsigned>           {};
template <> struct Typemap<unsigned long>       : TypemapNumeric<unsigned long>      {};
template <> struct Typemap<unsigned long long>  : TypemapNumeric<unsigned long long> {};
template <> struct Typemap<float>               : TypemapNumeric<float>              {};
template <> struct Typemap<double>              : TypemapNumeric<double>             {};

template <> struct Typemap<bool> : TypemapBase<bool> {
    static inline Sv   out (pTHX_ bool var, const Sv& = {}) { return Simple(var); }
    static inline bool in  (pTHX_ Sv arg)                   { return arg.is_true(); }
};

}
