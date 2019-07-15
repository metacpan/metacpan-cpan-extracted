#pragma once
#include <xs/Scalar.h>

namespace xs {

using xs::my_perl;

struct HashEntry {
    HashEntry (HE* he = NULL) : he(he) {}

    U32 hash () const { return HeHASH(he); }

    std::string_view key () const { return std::string_view(HeKEY(he), HeKLEN(he)); }

    HEK* hek () const { return HeKEY_hek(he); }

    Scalar value () const {
        Scalar ret;
        ret.set(HeVAL(he));
        return ret;
    }

    void value (const Scalar& val) {
        SvREFCNT_inc_simple_void(val.get());
        auto old = HeVAL(he);
        HeVAL(he) = val.get();
        SvREFCNT_dec(old);
    }
    void value (SV* v)              { value(Scalar(v)); }
    void value (const Sv& v)        { value(Scalar(v)); }
    void value (const CallProxy& p) { value(p.scalar()); }
    void value (const Array&) = delete;
    void value (const Hash&)  = delete;
    void value (const Sub&)   = delete;

    bool operator== (const HashEntry& oth) const { return he == oth.he; }

    explicit
    operator bool () const { return he; }

    operator HE* () const { return he; }

    HE* operator-> () const { return he; }

private:
    HE* he;
};

}
