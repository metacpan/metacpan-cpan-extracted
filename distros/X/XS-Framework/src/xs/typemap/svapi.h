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

template <> struct Typemap<AV*> : TypemapBase<AV*> {
    static inline AV* in (SV* arg) {
        if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) return (AV*)SvRV(arg);
        else if (SvOK(arg)) throw "argument is not an ARRAY reference";
        return nullptr;
    }
    static inline Sv out (AV* var, const Sv& = Sv()) {
        if (!var) return &PL_sv_undef;
        return Sv::noinc(newRV_noinc((SV*)var));
    }
};

template <> struct Typemap<HV*> : TypemapBase<HV*> {
    static inline HV* in (SV* arg) {
        if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVHV) return (HV*)SvRV(arg);
        else if (SvOK(arg)) throw "argument is not a HASH reference";
        return nullptr;
    }
    static inline Sv out (HV* var, const Sv& = Sv()) {
        if (!var) return &PL_sv_undef;
        return Sv::noinc(newRV_noinc((SV*)var));
    }
};

template <> struct Typemap<CV*> : TypemapBase<CV*> {
    static inline CV* in (SV* arg) {
        if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVCV) return (CV*)SvRV(arg);
        else if (SvOK(arg)) throw "argument is not a CODE reference";
        return nullptr;
    }
    static inline Sv out (CV* var, const Sv& = Sv()) {
        if (!var) return &PL_sv_undef;
        return Sv::noinc(newRV_noinc((SV*)var));
    }
};

template <> struct Typemap<IO*> : TypemapBase<IO*> {
    static inline IO* in (SV* arg) {
        if (SvROK(arg)) {
            SV* val = SvRV(arg);
            if (SvTYPE(val) == SVt_PVIO) return (IO*)val;
            if (SvTYPE(val) == SVt_PVGV && GvIOp(val)) return GvIOp(val);
        }
        else if (SvTYPE(arg) == SVt_PVGV && GvIOp(arg)) return GvIOp(arg);
        if (!SvOK(arg)) return nullptr;
        throw "argument is neither IO reference, nor glob or reference to glob containing IO slot)";
    }

    static inline Sv out (IO* var, const Sv& = Sv()) {
        if (!var) return &PL_sv_undef;
        return Sv::noinc(newRV_noinc((SV*)var));
    }
};

template <> struct Typemap<GV*> : TypemapBase<GV*> {
    static inline GV* in (SV* arg) {
        if (SvTYPE(arg) == SVt_PVGV) return (GV*)arg;
        else if (SvOK(arg)) throw "argument is not a GLOB";
        return nullptr;
    }
    static inline Sv out (GV* var, const Sv& = Sv()) {
        if (!var) return &PL_sv_undef;
        return Sv::noinc((SV*)var);
    }
};


template <class TYPE> struct Typemap<Sv, TYPE> : TypemapBase<Sv, TYPE> {
    static inline TYPE in  (SV* arg) { return arg; }
    static inline Sv out (const TYPE& var, const Sv& = Sv()) {
        if (!var) return &PL_sv_undef;
        return var;
    }
};
template <> struct Typemap<Scalar> : Typemap<Sv, Scalar> {};
template <> struct Typemap<Simple> : Typemap<Sv, Simple> {};
template <> struct Typemap<Ref>    : Typemap<Sv, Ref>    {};
template <> struct Typemap<Glob>   : Typemap<Sv, Glob>   {};

template <class TYPE> struct Typemap<Sub, TYPE> : TypemapBase<Sub, TYPE> {
    static inline TYPE in (SV* arg) { return arg; }
    static inline Sv out (const TYPE& var, const Sv& = Sv()) {
        if (!var) return &PL_sv_undef;
        return Ref::create(var);
    }
};
template <> struct Typemap<Array> : Typemap<Sub, Array> {};
template <> struct Typemap<Hash>  : Typemap<Sub, Hash>  {};
template <> struct Typemap<Stash> : Typemap<Sub, Stash> {};
template <> struct Typemap<Io>    : Typemap<Sub, Io>    {};

template <> struct Typemap<Object> : TypemapBase<Object> {
    static inline Object in (SV* arg) { return arg; }
    static inline Sv out (const Object& var, const Sv& = Sv()) {
        if (!var) return &PL_sv_undef;
        return var.ref();
    }
};

}
