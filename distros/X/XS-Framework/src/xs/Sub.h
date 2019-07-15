#pragma once
#include <functional>
#include <xs/Sv.h>
#include <xs/Array.h>
#include <initializer_list>

namespace xs {

using xs::my_perl;

struct Sub : Sv {
    static Sub noinc (SV* val) { return Sub(val, NONE); }
    static Sub noinc (CV* val) { return Sub(val, NONE); }

    Sub (std::nullptr_t = nullptr) {}
    Sub (SV* sv, bool policy = INCREMENT) : Sv(sv, policy) { _validate(); }
    Sub (CV* sv, bool policy = INCREMENT) : Sv(sv, policy) {}

    explicit
    Sub (std::string_view subname, I32 flags = 0) {
        *this = get_cvn_flags(subname.data(), subname.length(), flags);
    }

    Sub (const Sub& oth)     : Sv(oth)            {}
    Sub (Sub&& oth)          : Sv(std::move(oth)) {}
    Sub (const Sv& oth)      : Sv(oth)            { _validate(); }
    Sub (Sv&& oth)           : Sv(std::move(oth)) { _validate(); }
    Sub (const CallProxy& p) : Sub(p.sv())        {}

    Sub (const Simple&) = delete;
    Sub (const Array&)  = delete;
    Sub (const Hash&)   = delete;
    Sub (const Glob&)   = delete;

    Sub& operator= (SV* val)            { Sv::operator=(val); _validate(); return *this; }
    Sub& operator= (CV* val)            { Sv::operator=(val); return *this; }
    Sub& operator= (const Sub& oth)     { Sv::operator=(oth); return *this; }
    Sub& operator= (Sub&& oth)          { Sv::operator=(std::move(oth)); return *this; }
    Sub& operator= (const Sv& oth)      { return operator=(oth.get()); }
    Sub& operator= (Sv&& oth)           { Sv::operator=(std::move(oth)); _validate(); return *this; }
    Sub& operator= (const CallProxy& p) { return operator=(p.sv()); }
    Sub& operator= (const Simple&)      = delete;
    Sub& operator= (const Array&)       = delete;
    Sub& operator= (const Hash&)        = delete;
    Sub& operator= (const Glob&)        = delete;

    void set (SV* val) { Sv::operator=(val); }

    operator AV* () const = delete;
    operator HV* () const = delete;
    operator CV* () const { return (CV*)sv; }
    operator GV* () const = delete;

    CV* operator-> () const { return (CV*)sv; }

    template <typename T = SV> one_of_t<T,SV,CV>* get () const { return (T*)sv; }

    Stash stash () const;
    Glob  glob  () const;

    std::string_view name () const {
        GV* gv = CvGV((CV*)sv);
        return std::string_view(GvNAME(gv), GvNAMELEN(gv));
    }

    bool named () const { return CvNAMED((CV*)sv); }

    Sub SUPER () const {
        GV* mygv = CvGV((CV*)sv);
        GV* supergv = gv_fetchmeth_pvn(GvSTASH(mygv), GvNAME(mygv), GvNAMELEN(mygv), 0, GV_SUPER);
        return Sub(supergv ? GvCV(supergv) : nullptr);
    }

    Sub SUPER_strict () const {
        Sub ret = SUPER();
        if (!ret) _throw_super();
        return ret;
    }

    CallProxy call       ()                                                    const { return CallProxy((CV*)sv); }
    CallProxy call       (const Scalar& arg)                                   const { return CallProxy((CV*)sv, arg ? arg.get() : &PL_sv_undef); }
    CallProxy call       (SV*const* args, size_t items)                        const { return CallProxy((CV*)sv, NULL, args, items); }
    CallProxy call       (const Scalar& arg0, SV*const* args, size_t items)    const { return CallProxy((CV*)sv, arg0 ? arg0.get() : &PL_sv_undef, args, items); }
    CallProxy call       (std::initializer_list<Scalar> l)                     const { return CallProxy((CV*)sv, NULL, l.begin(), l.size()); }
    CallProxy call       (const Scalar& arg0, std::initializer_list<Scalar> l) const { return CallProxy((CV*)sv, arg0 ? arg0.get() : &PL_sv_undef, l.begin(), l.size()); }
    CallProxy operator() ()                                                    const { return call(); }
    CallProxy operator() (const Scalar& arg)                                   const { return call(arg); }
    CallProxy operator() (SV*const* args, size_t items)                        const { return call(args, items); }
    CallProxy operator() (const Scalar& arg0, SV*const* args, size_t items)    const { return call(arg0, args, items); }
    CallProxy operator() (std::initializer_list<Scalar> l)                     const { return call(l); }
    CallProxy operator() (const Scalar& arg0, std::initializer_list<Scalar> l) const { return call(arg0, l); }

private:
    void _validate () {
        if (!sv) return;
        if (SvTYPE(sv) == SVt_PVCV) return;
        if (SvROK(sv)) {           // reference to code?
            SV* val = SvRV(sv);
            if (SvTYPE(val) == SVt_PVCV) {
                Sv::operator=(val);
                return;
            }
        }
        if (is_undef()) return reset();
        reset();
        throw std::invalid_argument("wrong SV* type for Sub");
    }

    void _throw_super () const;
};

}
