#pragma once
#include <xs/Scalar.h>

namespace xs {

struct Sub; struct Hash; struct Array;

struct KeyProxy : Scalar {
    KeyProxy (SV** ptr, bool nullok) : Scalar(), ptr(ptr), nullok(nullok) { set(*ptr); }

    KeyProxy& operator= (std::nullptr_t)    { return operator=(Scalar()); }
    KeyProxy& operator= (const KeyProxy& v) { return operator=((Scalar)v); }
    KeyProxy& operator= (const Scalar& val) {
        Scalar::operator=(val);
        SV* newsv = val;
        if (nullok || newsv) SvREFCNT_inc_simple_void(newsv);
        else newsv = newSV(0);
        auto old = *ptr;
        *ptr = newsv;
        SvREFCNT_dec(old);
        return *this;
    }
    KeyProxy& operator= (SV* v)        { return operator=(Scalar(v)); }
    KeyProxy& operator= (const Sv& v)  { return operator=(Scalar(v)); }
    KeyProxy& operator= (const Array&) = delete;
    KeyProxy& operator= (const Hash&)  = delete;
    KeyProxy& operator= (const Sub&)   = delete;

    KeyProxy operator[] (size_t key);
    KeyProxy operator[] (const panda::string_view& key);

private:
    SV** ptr;
    bool nullok;
};

}
