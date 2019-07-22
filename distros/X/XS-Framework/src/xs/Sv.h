#pragma once
#include "basic.h"
#include <string>
#include <panda/memory.h>
#include <panda/traits.h>
#include <panda/string_view.h>

namespace xs {

struct Sv; struct Scalar; struct Simple; struct Ref; struct Array; struct Hash; struct List; struct Sub; struct Stash; struct Glob; struct Object;
using xs::my_perl;

template <class T, class R = T> using enable_if_sv_t    = std::enable_if_t<panda::is_one_of<T,Sv,Scalar,Ref,Simple,Object,Sub,Hash,Array,Glob,Stash,List>::value, R>;
template <class T, class R = T> using enable_if_rawsv_t = std::enable_if_t<panda::is_one_of<T,SV,AV,HV,CV,GV>::value, R>;

struct Sv {
    static const bool INCREMENT = true;
    static const bool NONE      = false;

    static const Sv undef;
    static const Sv yes;
    static const Sv no;

    typedef int (*on_svdup_t) (pTHX_ MAGIC* mg, CLONE_PARAMS* param);
    using payload_marker_t = MGVTBL;

    struct Payload {
        void* ptr;
        SV*   obj;
    };

    template <class T> struct PayloadMarker {
        PANDA_GLOBAL_MEMBER_AS_PTR(PayloadMarker, payload_marker_t, get, payload_marker_t());
    };

    static payload_marker_t* default_marker();

    template <class T, typename = enable_if_rawsv_t<T>>
    static Sv noinc (T* val) { return Sv((SV*)val, NONE); }

    static Sv create () { return Sv(newSV(0), NONE); }

    Sv (std::nullptr_t = nullptr) : sv(nullptr) {}

    template <class T, typename = enable_if_rawsv_t<T>>
    Sv (T* sv, bool policy = INCREMENT) : sv((SV*)sv) { if (policy == INCREMENT) SvREFCNT_inc_simple_void(sv); }

    Sv (const Sv& oth) : Sv(oth.sv) {}
    Sv (Sv&&      oth) : sv(oth.sv) { oth.sv = nullptr; }

    ~Sv () { SvREFCNT_dec(sv); }

    template <class T, typename = enable_if_rawsv_t<T>>
    Sv& operator= (T* val) {
        SvREFCNT_inc_simple_void(val);
        auto old = sv;
        sv = (SV*)val;
        SvREFCNT_dec(old);
        return *this;
    }

    Sv& operator= (const Sv& oth) { return operator=(oth.sv); }

    Sv& operator= (Sv&& oth) {
        std::swap(sv, oth.sv);
        return *this;
    }

    // safe getters (slower)
    operator SV*   () const { return sv; }
    operator AV*   () const { return is_array() ? (AV*)sv : nullptr; }
    operator HV*   () const { return is_hash()  ? (HV*)sv : nullptr; }
    operator CV*   () const { return is_sub()   ? (CV*)sv : nullptr; }
    operator GV*   () const { return is_glob()  ? (GV*)sv : nullptr; }
    operator void* () const { return sv; } // resolves ambiguity for passing to perl-macros-api

    // unsafe getters (faster)
    template <typename T = SV> enable_if_rawsv_t<T>* get () const { return (T*)sv; }

    explicit operator bool () const { return sv; }
    explicit operator bool ()       { return sv; }

    SV* operator-> () const { return sv; }

    bool   defined        () const { return sv && SvOK(sv); }
    bool   is_true        () const { return SvTRUE_nomg(sv); }
    svtype type           () const { return SvTYPE(sv); }
    bool   readonly       () const { return SvREADONLY(sv); }
    U32    use_count      () const { return sv ? SvREFCNT(sv) : 0; }
    bool   is_scalar      () const { return sv && is_scalar_unsafe(); }
    bool   is_ref         () const { return sv && SvROK(sv); }
    bool   is_simple      () const { return sv && SvTYPE(sv) <= SVt_PVMG && !SvROK(sv); }
    bool   is_string      () const { return sv && SvPOK(sv); }
    bool   is_like_number () const { return sv && looks_like_number(sv); }
    bool   is_array       () const { return sv && type() == SVt_PVAV; }
    bool   is_array_ref   () const { return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV; }
    bool   is_hash        () const { return sv && type() == SVt_PVHV; }
    bool   is_hash_ref    () const { return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV; }
    bool   is_sub         () const { return sv && type() == SVt_PVCV; }
    bool   is_sub_ref     () const { return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV; }
    bool   is_glob        () const { return sv && type() == SVt_PVGV; }
    bool   is_object      () const { return sv && SvOBJECT(sv); }
    bool   is_object_ref  () const { return sv && SvROK(sv) && SvOBJECT(SvRV(sv)); }
    bool   is_stash       () const { return is_hash() && HvNAME(sv); }

    void readonly (bool val) {
        if (val) SvREADONLY_on(sv);
        else SvREADONLY_off(sv);
    }

    void upgrade (svtype type) {
        if (SvREADONLY(sv)) throw "cannot upgrade readonly sv";
        if (type > SVt_PVMG && SvOK(sv)) throw "only undefined scalars can be upgraded to something more than SVt_PVMG";
        SvUPGRADE(sv, type);
    }

    void dump () const { sv_dump(sv); }

    MAGIC* payload_attach (Payload p, const payload_marker_t* marker) { return payload_attach(p.ptr, p.obj, marker); }
    MAGIC* payload_attach (void* ptr, SV* obj, const payload_marker_t* marker);
    MAGIC* payload_attach (void* ptr, const Sv& obj, const payload_marker_t* marker) { return payload_attach(ptr, (SV*)obj, marker); }

    MAGIC* payload_attach (const Sv& obj, const payload_marker_t* marker) { return payload_attach(NULL, obj, marker); }
    MAGIC* payload_attach (SV* obj, const payload_marker_t* marker) { return payload_attach(NULL, obj, marker); }
    MAGIC* payload_attach (void* ptr, const payload_marker_t* marker) { return payload_attach(ptr, NULL, marker); }

    bool payload_exists (const payload_marker_t* marker) const {
        if (type() < SVt_PVMG) return false;
        for (MAGIC* mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) if (mg->mg_virtual == marker) return true;
        return false;
    }

    Payload payload (const payload_marker_t* marker) const {
        if (type() < SVt_PVMG) return Payload();
        for (MAGIC* mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) if (mg->mg_virtual == marker) return Payload { mg->mg_ptr, mg->mg_obj };
        return Payload();
    }

    int payload_detach (payload_marker_t* marker) {
        if (type() < SVt_PVMG) return 0;
        return sv_unmagicext(sv, PERL_MAGIC_ext, marker);
    }

    void reset () {
        SvREFCNT_dec(sv);
        sv = nullptr;
    }

    SV* detach () {
        auto tmp = sv;
        sv = nullptr;
        return tmp;
    }

    static void __at_perl_destroy ();

protected:
    inline bool is_undef() const { return (SvTYPE(sv) <= SVt_PVMG && !SvOK(sv)); }
    inline bool is_scalar_unsafe() const { return (SvTYPE(sv) <= SVt_PVMG || SvTYPE(sv) == SVt_PVGV); }
    SV* sv;
};

inline bool operator== (const Sv& lh, const Sv& rh) { return lh.get<SV>() == rh.get<SV>(); }
inline bool operator!= (const Sv& lh, const Sv& rh) { return !(lh == rh); }

template <class T, typename = enable_if_rawsv_t<T>> inline bool operator== (const Sv& lh, T* rh) { return lh.get() == (SV*)rh; }
template <class T, typename = enable_if_rawsv_t<T>> inline bool operator!= (const Sv& lh, T* rh) { return lh.get() != (SV*)rh; }
template <class T, typename = enable_if_rawsv_t<T>> inline bool operator== (T* lh, const Sv& rh) { return rh.get() == (SV*)lh; }
template <class T, typename = enable_if_rawsv_t<T>> inline bool operator!= (T* lh, const Sv& rh) { return rh.get() != (SV*)lh; }

std::ostream& operator<< (std::ostream& os, const Sv& sv);

}
