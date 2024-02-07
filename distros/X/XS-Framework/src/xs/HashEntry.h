#pragma once
#include <xs/Scalar.h>

namespace xs {

using xs::my_perl;

struct HashEntry {
    HashEntry (HE* he = NULL) : he(he) {}

    U32 hash () const { return HeHASH(he); }

    panda::string_view key () const { return panda::string_view(HeKEY(he), HeKLEN(he)); }

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
    void value (SV* v)        { value(Scalar(v)); }
    void value (const Sv& v)  { value(Scalar(v)); }
    void value (const Array&) = delete;
    void value (const Hash&)  = delete;
    void value (const Sub&)   = delete;
    void value (const Io&)    = delete;

    bool operator== (const HashEntry& oth) const { return he == oth.he; }

    explicit
    operator bool () const { return he; }

    operator HE* () const { return he; }

    HE* operator-> () const { return he; }

private:
    HE* he;
};

}

#if (__cplusplus >= 201703L)
// structured bindings for C++17 and newer
namespace std
{

template<>
struct tuple_size<xs::HashEntry>
{
    static constexpr size_t value = 2;
};

template<>
struct tuple_element<0, xs::HashEntry>
{
    using type = panda::string_view;
};

template<>
struct tuple_element<1, xs::HashEntry>
{
    using type = xs::Scalar;
};

}//namespace std

namespace xs {

template<std::size_t Index>
std::tuple_element_t<Index, xs::HashEntry> get(const xs::HashEntry& he)
{
    if constexpr (Index == 0) return he.key();
    if constexpr (Index == 1) return he.value();
}

}
#endif
