#pragma once
#include "base.h"
#include "../Ref.h"
#include "../Sub.h"
#include "../Hash.h"
#include "../Glob.h"
#include "../Stash.h"
#include "../Array.h"
#include "../Object.h"
#include "../Simple.h"

namespace xs {

namespace typemap { namespace svapi {
    static inline void _throw (const Scalar&) { throw "arg is not a scalar value"; }
    static inline void _throw (const Simple&) { throw "arg is not a simple value"; }
    static inline void _throw (const Ref&)    { throw "arg is not a reference"; }
    static inline void _throw (const Glob&)   { throw "arg is not a glob value"; }
    static inline void _throw (const Sub&)    { throw "arg is not a code reference"; }
    static inline void _throw (const Array&)  { throw "arg is not an array reference"; }
    static inline void _throw (const Hash&)   { throw "arg is not a hash reference"; }
    static inline void _throw (const Stash&)  { throw "arg is not a stash reference"; }
    static inline void _throw (const Object&) { throw "arg is not a blessed reference"; }
}}

template <> struct Typemap<AV*> : TypemapBase<AV*> {
    static inline AV* in (pTHX_ SV* arg) {
        if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) return (AV*)SvRV(arg);
        else if (SvOK(arg)) throw "argument is not an ARRAY reference";
        return nullptr;
    }
    static inline Sv out (pTHX_ AV* var, const Sv& = Sv()) {
        if (!var) return &PL_sv_undef;
        return Sv::noinc(newRV_noinc((SV*)var));
    }
};

template <> struct Typemap<HV*> : TypemapBase<HV*> {
    static inline HV* in (pTHX_ SV* arg) {
        if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVHV) return (HV*)SvRV(arg);
        else if (SvOK(arg)) throw "argument is not a HASH reference";
        return nullptr;
    }
    static inline Sv out (pTHX_ HV* var, const Sv& = Sv()) {
        if (!var) return &PL_sv_undef;
        return Sv::noinc(newRV_noinc((SV*)var));
    }
};

template <> struct Typemap<CV*> : TypemapBase<CV*> {
    static inline CV* in (pTHX_ SV* arg) {
        if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVCV) return (CV*)SvRV(arg);
        else if (SvOK(arg)) throw "argument is not a CODE reference";
        return nullptr;
    }
    static inline Sv out (pTHX_ CV* var, const Sv& = Sv()) {
        if (!var) return &PL_sv_undef;
        return Sv::noinc(newRV_noinc((SV*)var));
    }
};

template <> struct Typemap<IO*> : TypemapBase<IO*> {
    static inline IO* in (pTHX_ SV* arg) {
        if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVIO) return (IO*)SvRV(arg);
        if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVGV) {
            IO* var = GvIO(SvRV(arg));
            if (var) return var;
        }
        if (!SvOK(arg)) return nullptr;
        throw "argument is not an IO reference";
    }

    static inline Sv out (pTHX_ IO* var, const Sv& = Sv()) {
        if (!var) return &PL_sv_undef;
        return Sv::noinc(newRV_noinc((SV*)var));
    }
};

template <> struct Typemap<GV*> : TypemapBase<GV*> {
    static inline GV* in (pTHX_ SV* arg) {
        if (SvTYPE(arg) == SVt_PVGV) return (GV*)arg;
        else if (SvOK(arg)) throw "argument is not a GLOB";
        return nullptr;
    }
    static inline Sv out (pTHX_ GV* var, const Sv& = Sv()) {
        if (!var) return &PL_sv_undef;
        return Sv::noinc((SV*)var);
    }
};


template <> struct Typemap<Sv> : TypemapBase<Sv> {
    static inline Sv in  (pTHX_ SV* arg) { return arg; }
    static inline Sv out (pTHX_ const Sv& var, const Sv& = Sv()) {
        if (!var) return &PL_sv_undef;
        return var;
    }
};

template <class TYPE> struct Typemap<Scalar, TYPE> : TypemapBase<Scalar, TYPE> {
    static inline TYPE in (pTHX_ SV* arg) {
        TYPE ret = arg;
        if (!ret && SvOK(arg)) typemap::svapi::_throw(TYPE());
        return ret;
    }
    static inline Sv out (pTHX_ const TYPE& var, const Sv& = Sv()) { return var; }
};

template <> struct Typemap<Simple> : Typemap<Scalar, Simple> {};
template <> struct Typemap<Ref>    : Typemap<Scalar, Ref>    {};
template <> struct Typemap<Glob>   : Typemap<Scalar, Glob>   {};

template <class TYPE> struct Typemap<Sub, TYPE> : TypemapBase<Sub, TYPE> {
    static inline TYPE in (pTHX_ SV* arg) {
        TYPE ret = arg;
        if (!ret && SvOK(arg)) typemap::svapi::_throw(TYPE());
        return ret;
    }
    static inline Sv out (pTHX_ const TYPE& var, const Sv& = Sv()) {
        if (!var) return &PL_sv_undef;
        return Ref::create(var);
    }
};

template <> struct Typemap<Array> : Typemap<Sub, Array> {};
template <> struct Typemap<Hash>  : Typemap<Sub, Hash>  {};
template <> struct Typemap<Stash> : Typemap<Sub, Stash> {};

template <> struct Typemap<Object> : TypemapBase<Object> {
    static inline Object in (pTHX_ SV* arg) {
        Object ret = arg;
        if (!ret && SvOK(arg)) typemap::svapi::_throw(Object());
        return ret;
    }
    static inline Sv out (pTHX_ const Object& var, const Sv& = Sv()) {
        if (!var) return &PL_sv_undef;
        return var.ref();
    }
};

}
