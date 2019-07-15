#pragma once
#include "../Sv.h"

namespace xs {

namespace typemap {
    struct DefaultType {};
}

template <class TYPEMAP, class TYPE = TYPEMAP> struct Typemap { using _not_exists = void; };

template <class T, typename = void> struct has_typemap : std::true_type {};
template <class T> struct has_typemap<T, typename Typemap<T>::_not_exists> : std::false_type {};

template <class TYPEMAP, class TYPE = TYPEMAP> struct TypemapBase {
    static inline TYPE in (pTHX_ SV*) = delete;

    static inline Sv create (pTHX_ const TYPE&, const Sv& = Sv()) = delete;

    static inline Sv out (pTHX_ const TYPE& var, const Sv& proto = Sv()) {
        return Typemap<TYPE>::create(aTHX_ var, proto);
    }

    static inline void destroy (pTHX_ const TYPE&, SV*) {}
};

template <class TYPE>
auto in (SV* arg) -> decltype(Typemap<TYPE>::in(aTHX_ arg)) {
    return Typemap<TYPE>::in(aTHX_ arg);
}

template <class TYPEMAP = typemap::DefaultType, class TYPE, typename TM = std::conditional_t<std::is_same<TYPEMAP, typemap::DefaultType>::value, std::decay_t<TYPE>, TYPEMAP>>
Sv out (TYPE&& var, const Sv& proto = Sv()) {
    return Typemap<TM>::out(aTHX_ std::forward<TYPE>(var), proto);
}

#ifdef USE_ITHREADS
    template <class TYPE>
    auto in (pTHX_ SV* arg) -> decltype(Typemap<TYPE>::in(aTHX_ arg)) {
        return Typemap<TYPE>::in(aTHX_ arg);
    }

    template <class TYPEMAP = typemap::DefaultType, class TYPE, typename TM = std::conditional_t<std::is_same<TYPEMAP, typemap::DefaultType>::value, std::decay_t<TYPE>, TYPEMAP>>
    Sv out (pTHX_ TYPE&& var, const Sv& proto = Sv()) {
        return Typemap<TM>::out(aTHX_ std::forward<TYPE>(var), proto);
    }
#endif

}
