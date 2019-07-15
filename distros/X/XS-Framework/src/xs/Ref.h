#pragma once
#include <xs/Scalar.h>

namespace xs {

using xs::my_perl;

struct Ref : Scalar {
    Ref (std::nullptr_t = nullptr) {}
    Ref (SV* sv, bool policy = INCREMENT) : Scalar(sv, policy) { _validate(); }

    Ref (const Ref&    oth) : Scalar(oth)            {}
    Ref (Ref&&         oth) : Scalar(std::move(oth)) {}
    Ref (const Scalar& oth) : Scalar(oth)            { _validate(); }
    Ref (Scalar&&      oth) : Scalar(std::move(oth)) { _validate(); }
    Ref (const Sv&     oth) : Ref(oth.get())         {}
    Ref (Sv&&          oth) : Scalar(std::move(oth)) { _validate(); }

    Ref (const CallProxy& p) : Ref(p.scalar()) {}

    Ref (const Simple&) = delete;
    Ref (const Glob&)   = delete;
    Ref (const Array&) = delete;
    Ref (const Hash&)  = delete;
    Ref (const Sub&)   = delete;

    static Ref create (SV* sv = nullptr, bool policy = INCREMENT) {
        SV* rv;
        if (sv) rv = (policy == INCREMENT) ? newRV(sv) : newRV_noinc(sv);
        else rv = newRV_noinc(newSV(0));
        return Ref(rv, NONE);
    }
    static Ref create (AV* sv, bool policy = INCREMENT) { return create((SV*)sv, policy); }
    static Ref create (HV* sv, bool policy = INCREMENT) { return create((SV*)sv, policy); }
    static Ref create (CV* sv, bool policy = INCREMENT) { return create((SV*)sv, policy); }
    static Ref create (GV* sv, bool policy = INCREMENT) { return create((SV*)sv, policy); }

    static Ref create (const Sv& o) { return create(o.get()); }

    Ref& operator= (SV* val) {
        Scalar::operator=(val);
        _validate();
        return *this;
    }

    Ref& operator= (const Ref& oth) {
        Scalar::operator=(oth.sv);
        return *this;
    }

    Ref& operator= (Ref&& oth) {
        Scalar::operator=(std::move(oth));
        return *this;
    }

    Ref& operator= (const Scalar& oth) {
        Scalar::operator=(oth);
        _validate();
        return *this;
    }

    Ref& operator= (Scalar&& oth) {
        Scalar::operator=(std::move(oth));
        _validate();
        return *this;
    }

    Ref& operator= (const Sv& oth) { return operator=(oth.get()); }

    Ref& operator= (Sv&& oth) {
        Scalar::operator=(std::move(oth));
        _validate();
        return *this;
    }

    Ref& operator= (const CallProxy& p) { return operator=(p.scalar()); }

    Ref& operator= (const Simple&) = delete;
    Ref& operator= (const Glob&)   = delete;
    Ref& operator= (const Array&)  = delete;
    Ref& operator= (const Hash&)   = delete;
    Ref& operator= (const Sub&)    = delete;

    void set (SV* val) { Scalar::set(val); }

    template <class T = Sv> one_of_t<T,Sv,Scalar,Simple,Array,Hash,Sub,Stash,Glob,Ref,Object> value () const { return T(sv ? SvRV(sv) : NULL); }

    void value (SV* val, bool policy = INCREMENT) {
        if (!val) val = &PL_sv_undef;
        else if (policy == INCREMENT) SvREFCNT_inc_simple_void_NN(val);
        if (sv) {
            SvREFCNT_dec_NN(SvRV(sv));
            SvRV_set(sv, val);
        }
        else sv = newRV_noinc(val);
    }
    void value (AV* val, bool policy = INCREMENT) { value((SV*)val, policy); }
    void value (HV* val, bool policy = INCREMENT) { value((SV*)val, policy); }
    void value (CV* val, bool policy = INCREMENT) { value((SV*)val, policy); }
    void value (GV* val, bool policy = INCREMENT) { value((SV*)val, policy); }
    void value (const Sv& val)                    { value(val.get()); }
    void value (std::nullptr_t)                   { value((SV*)nullptr); }

private:
    inline void _validate () {
        if (!sv) return;
        if (SvROK(sv)) return;
        if (is_undef()) return reset();
        reset();
        throw std::invalid_argument("wrong SV* type for Ref");
    }
};

}
