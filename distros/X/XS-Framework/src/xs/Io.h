#pragma once
#include <xs/Sv.h>

// remove OpenBSD pollution macro
#undef fileno

namespace xs {

using xs::my_perl;

struct Io : Sv {
    static Io noinc (SV* val) { return Io(val, NONE); }
    static Io noinc (IO* val) { return Io(val, NONE); }

    Io (std::nullptr_t = nullptr) {}
    Io (SV* sv, bool policy = INCREMENT) : Sv(sv, policy) { _validate(); }
    Io (GV* sv, bool policy = INCREMENT) : Sv(sv, policy) { _validate(); }
    Io (IO* sv, bool policy = INCREMENT) : Sv(sv, policy) {}

    Io (const Io& oth) : Sv(oth)            {}
    Io (Io&& oth)      : Sv(std::move(oth)) {}
    Io (const Sv& oth) : Sv(oth)            { _validate(); }
    Io (Sv&& oth)      : Sv(std::move(oth)) { _validate(); }

    Io (const Simple&) = delete;
    Io (const Array&)  = delete;
    Io (const Hash&)   = delete;
    Io (const Sub&)    = delete;

    Io& operator= (SV* val)       { Sv::operator=(val); _validate(); return *this; }
    Io& operator= (GV* val)       { Sv::operator=(val); _validate(); return *this; }
    Io& operator= (IO* val)       { Sv::operator=(val); return *this; }
    Io& operator= (const Io& oth) { Sv::operator=(oth); return *this; }
    Io& operator= (Io&& oth)      { Sv::operator=(std::move(oth)); return *this; }
    Io& operator= (const Sv& oth) { return operator=(oth.get()); }
    Io& operator= (Sv&& oth)      { Sv::operator=(std::move(oth)); _validate(); return *this; }
    Io& operator= (const Simple&) = delete;
    Io& operator= (const Array&)  = delete;
    Io& operator= (const Hash&)   = delete;
    Io& operator= (const Sub&)    = delete;

    void set (SV* val) { Sv::operator=(val); }

    operator AV* () const = delete;
    operator HV* () const = delete;
    operator CV* () const = delete;
    operator GV* () const = delete;
    operator IO* () const { return (IO*)sv; }

    IO* operator-> () const { return (IO*)sv; }

    template <typename T = SV> panda::enable_if_one_of_t<T,SV,IO>* get () const { return (T*)sv; }

    int fileno () const { return PerlIO_fileno(ifp()); }

    PerlIO* ifp () const { return IoIFP(sv); }
    PerlIO* ofp () const { return IoOFP(sv); }

    char iotype () const { return IoTYPE(sv); }

private:
    void _validate ();
};

}
