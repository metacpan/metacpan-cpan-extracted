#pragma once
#include <xs/Sub.h>
#include <xs/Hash.h>
#include <xs/Array.h>
#include <xs/Scalar.h>

namespace xs {

using xs::my_perl;

struct Glob : Scalar {
    static Glob create (const Stash& stash, panda::string_view name, U32 flags = 0);

    Glob (std::nullptr_t = nullptr) {}
    Glob (SV* sv, bool policy = INCREMENT) : Scalar(sv, policy) { _validate(); }
    Glob (GV* sv, bool policy = INCREMENT) : Scalar(sv, policy) {}

    Glob (const Glob&   oth) : Scalar(oth)            {}
    Glob (Glob&&        oth) : Scalar(std::move(oth)) {}
    Glob (const Scalar& oth) : Scalar(oth)            { _validate(); }
    Glob (Scalar&&      oth) : Scalar(std::move(oth)) { _validate(); }
    Glob (const Sv&     oth) : Scalar(oth)            { _validate(); }
    Glob (Sv&&          oth) : Scalar(std::move(oth)) { _validate(); }

    Glob (const Simple&) = delete;
    Glob (const Ref&)    = delete;
    Glob (const Array&)  = delete;
    Glob (const Hash&)   = delete;
    Glob (const Sub&)    = delete;

    Glob& operator= (SV* val)           { Scalar::operator=(val); _validate(); return *this; }
    Glob& operator= (GV* val)           { Scalar::operator=(val); return *this; }
    Glob& operator= (const Glob& oth)   { Scalar::operator=(oth); return *this; }
    Glob& operator= (Glob&& oth)        { Scalar::operator=(std::move(oth)); return *this; }
    Glob& operator= (const Scalar& oth) { Scalar::operator=(oth); _validate(); return *this; }
    Glob& operator= (Scalar&& oth)      { Scalar::operator=(std::move(oth)); _validate(); return *this; }
    Glob& operator= (const Sv& oth)     { return operator=(oth.get()); }
    Glob& operator= (Sv&& oth)          { Sv::operator=(std::move(oth)); _validate(); return *this; }
    Glob& operator= (const Simple&)     = delete;
    Glob& operator= (const Ref&)        = delete;
    Glob& operator= (const Array&)      = delete;
    Glob& operator= (const Hash&)       = delete;
    Glob& operator= (const Sub&)        = delete;

    void set (SV* val) { Sv::operator=(val); }
    void set (GV* val) { Sv::operator=(val); }

    operator AV* () const = delete;
    operator HV* () const = delete;
    operator CV* () const = delete;
    operator GV* () const { return (GV*)sv; }

    GV* operator->() const { return (GV*)sv; }

    template <typename T = SV> panda::enable_if_one_of_t<T,SV,GV>* get () const { return (T*)sv; }

    template <typename T> panda::enable_if_one_of_t<T,Scalar,Array,Hash,Sub> slot () const;

    Scalar scalar () const { return sv ? GvSV((GV*)sv) : NULL; }
    Array  array  () const { return sv ? GvAV((GV*)sv) : NULL; }
    Hash   hash   () const { return sv ? GvHV((GV*)sv) : NULL; }
    Sub    sub    () const { return sv ? GvCV((GV*)sv) : NULL; }

    void slot (SV*);
    void slot (AV*);
    void slot (HV*);
    void slot (CV*);
    void slot (const Scalar&);
    void slot (const Sv&     v) { slot(v.get()); }
    void slot (const Array&  v) { slot(v.get<AV>()); }
    void slot (const Hash&   v) { slot(v.get<HV>()); }
    void slot (const Sub&    v) { slot(v.get<CV>()); }
    void slot (GV*)             = delete;
    void slot (const Glob&)     = delete;

    void scalar (const Scalar& val) { slot(val); }
    void array  (const Array&  val) { slot(val); }
    void hash   (const Hash&   val) { slot(val); }
    void sub    (const Sub&    val) { slot(val); }

    Sv get_const () const { return gv_const_sv((GV*)sv); }

    panda::string_view name           () const { return panda::string_view(GvNAME((GV*)sv), GvNAMELEN((GV*)sv)); }
    panda::string_view effective_name () const { return panda::string_view(GvENAME((GV*)sv), GvENAMELEN((GV*)sv)); }

    Stash stash           () const;
    Stash effective_stash () const;

private:
    void _validate () {
        if (!sv) return;
        if (type() == SVt_PVGV) return;
        if (is_undef()) return reset();
        reset();
        throw std::invalid_argument("wrong SV* type for Glob");
    }
};

template <> inline Scalar Glob::slot<Scalar> () const { return scalar(); }
template <> inline Array  Glob::slot<Array>  () const { return array(); }
template <> inline Hash   Glob::slot<Hash>   () const { return hash(); }
template <> inline Sub    Glob::slot<Sub>    () const { return sub(); }

}
