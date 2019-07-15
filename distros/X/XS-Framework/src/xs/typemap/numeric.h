#pragma once
#include "base.h"
#include "../Simple.h" // for _getnum()

namespace xs {

template <class TYPE> struct TypemapNumeric : TypemapBase<TYPE> {
    static inline TYPE in  (pTHX_ SV* arg)                    { return _getnum<TYPE>(arg); }
    static inline Sv   out (pTHX_ TYPE var, const Sv& = Sv()) { return Simple(var); }
};

template <> struct Typemap<int8_t>   : TypemapNumeric<int8_t>   {};
template <> struct Typemap<int16_t>  : TypemapNumeric<int16_t>  {};
template <> struct Typemap<int32_t>  : TypemapNumeric<int32_t>  {};
template <> struct Typemap<int64_t>  : TypemapNumeric<int64_t>  {};
template <> struct Typemap<uint8_t>  : TypemapNumeric<uint8_t>  {};
template <> struct Typemap<uint16_t> : TypemapNumeric<uint16_t> {};
template <> struct Typemap<uint32_t> : TypemapNumeric<uint32_t> {};
template <> struct Typemap<uint64_t> : TypemapNumeric<uint64_t> {};
template <> struct Typemap<float>    : TypemapNumeric<float>    {};
template <> struct Typemap<double>   : TypemapNumeric<double>   {};

template <> struct Typemap<bool> : TypemapBase<bool> {
    static inline Sv   out (pTHX_ bool var, const Sv& = {}) { return Simple(var); }
    static inline bool in  (pTHX_ Sv arg)                   { return arg.is_true(); }
};

}
