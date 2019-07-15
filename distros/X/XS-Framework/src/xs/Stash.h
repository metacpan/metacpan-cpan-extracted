#pragma once
#include <xs/Sub.h>
#include <xs/Hash.h>
#include <xs/Glob.h>
#include <xs/next.h>
#include <xs/Array.h>
#include <xs/Scalar.h>
#include <xs/Simple.h>
#include <panda/string.h>

namespace xs {

using xs::my_perl;

struct Stash : Hash {
    struct op_proxy : Glob {
        op_proxy (SV** ptr) : Glob(), ptr(ptr) { if (ptr) set(*ptr); }

        op_proxy& operator= (SV*);
        op_proxy& operator= (AV* v) { _assert(); slot(v); return *this; }
        op_proxy& operator= (HV* v) { _assert(); slot(v); return *this; }
        op_proxy& operator= (CV* v) { _assert(); slot(v); return *this; }
        op_proxy& operator= (GV*);
        op_proxy& operator= (std::nullptr_t)     { return operator=((SV*)NULL); }
        op_proxy& operator= (const Sv& v)        { return operator=(v.get()); }
        op_proxy& operator= (const Scalar& v)    { _assert(); slot(v); return *this; }
        op_proxy& operator= (const Array& v)     { _assert(); slot(v); return *this; }
        op_proxy& operator= (const Hash& v)      { _assert(); slot(v); return *this; }
        op_proxy& operator= (const Sub& v)       { _assert(); slot(v); return *this; }
        op_proxy& operator= (const Glob& v)      { return operator=(v.get<GV>()); }
        op_proxy& operator= (const op_proxy& v)  { return operator=(v.get<GV>()); }
        op_proxy& operator= (const CallProxy& p) { return operator=(p.scalar()); }

        inline void _assert () { if (!ptr) throw std::logic_error("store: empty object"); }

    private:
        SV** ptr;
    };

    static Stash root () { return PL_defstash; }

    static Stash from_name (SV* fqn, I32 flags = 0) { return gv_stashsv(fqn, flags); }

    Stash (std::nullptr_t = nullptr) {}
    Stash (SV* sv, bool policy = INCREMENT) : Hash(sv, policy) { _validate(); }
    Stash (HV* sv, bool policy = INCREMENT) : Hash(sv, policy) { _validate(); }

    Stash (const std::string_view& package, I32 flags = 0) {
        *this = gv_stashpvn(package.data(), package.length(), flags);
    }

    Stash (const Stash& oth) : Hash(oth)            {}
    Stash (const Hash&  oth) : Hash(oth)            { _validate(); }
    Stash (const Sv&    oth) : Stash(oth.get())     {}
    Stash (Stash&&      oth) : Hash(std::move(oth)) {}
    Stash (Hash&&       oth) : Hash(std::move(oth)) { _validate(); }
    Stash (Sv&&         oth) : Hash(std::move(oth)) { _validate(); }

    Stash (const CallProxy& p) : Stash(p.sv()) {}

    Stash (const Simple&) = delete;
    Stash (const Array&)  = delete;
    Stash (const Sub&)    = delete;
    Stash (const Glob&)   = delete;

    Stash& operator= (SV* val)            { Hash::operator=(val); _validate(); return *this; }
    Stash& operator= (HV* val)            { Hash::operator=(val); _validate(); return *this; }
    Stash& operator= (const Stash& oth)   { Hash::operator=(oth); return *this; }
    Stash& operator= (Stash&& oth)        { Hash::operator=(std::move(oth)); return *this; }
    Stash& operator= (const Hash& oth)    { Hash::operator=(oth); _validate(); return *this; }
    Stash& operator= (Hash&& oth)         { Hash::operator=(std::move(oth)); _validate(); return *this; }
    Stash& operator= (const Sv& oth)      { return operator=(oth.get()); }
    Stash& operator= (Sv&& oth)           { Hash::operator=(std::move(oth)); _validate(); return *this; }
    Stash& operator= (const CallProxy& p) { return operator=(p.sv()); }
    Stash& operator= (const Simple&)      = delete;
    Stash& operator= (const Array&)       = delete;
    Stash& operator= (const Sub&)         = delete;
    Stash& operator= (const Glob&)        = delete;

    using Hash::set;
    void set (HV* val) { Hash::operator=(val); }

    Glob fetch (const std::string_view& key) const {
        auto elem = Hash::fetch(key);
        _promote(elem.get<GV>(), key);
        return elem.get<GV>();
    }

    Glob at (const std::string_view& key) const {
        Glob ret = fetch(key);
        if (!ret) throw std::out_of_range("at: no key");
        return ret;
    }

    Glob operator[] (const std::string_view& key) const { return fetch(key); }

    void store (const std::string_view& key, SV* v)              { operator[](key) = v; }
    void store (const std::string_view& key, AV* v)              { operator[](key) = v; }
    void store (const std::string_view& key, HV* v)              { operator[](key) = v; }
    void store (const std::string_view& key, CV* v)              { operator[](key) = v; }
    void store (const std::string_view& key, GV* v)              { operator[](key) = v; }
    void store (const std::string_view& key, const Sv&     v)    { operator[](key) = v; }
    void store (const std::string_view& key, const Scalar& v)    { operator[](key) = v; }
    void store (const std::string_view& key, const Array&  v)    { operator[](key) = v; }
    void store (const std::string_view& key, const Hash&   v)    { operator[](key) = v; }
    void store (const std::string_view& key, const Sub&    v)    { operator[](key) = v; }
    void store (const std::string_view& key, const Glob&   v)    { operator[](key) = v; }
    void store (const std::string_view& key, const CallProxy& p) { operator[](key) = p.scalar(); }

    op_proxy operator[] (const std::string_view& key) {
        if (!sv) return NULL;
        SV** ref = hv_fetch((HV*)sv, key.data(), key.length(), 1);
        _promote((GV*)*ref, key);
        return ref;
    }

    std::string_view name           () const { return std::string_view(HvNAME(sv), HvNAMELEN(sv)); }
    HEK*             name_hek       () const { return HvNAME_HEK_NN((HV*)sv); }
    const Simple&    name_sv        () const { if (!_name_sv) _name_sv = Simple::shared(name_hek()); return _name_sv; }
    std::string_view effective_name () const { return std::string_view(HvENAME(sv), HvENAMELEN(sv)); }
    panda::string    path           () const;

    Scalar scalar (const std::string_view& name) const { return fetch(name).scalar(); }
    Array  array  (const std::string_view& name) const { return fetch(name).array(); }
    Hash   hash   (const std::string_view& name) const { return fetch(name).hash(); }
    Sub    sub    (const std::string_view& name) const { return fetch(name).sub(); }

    void scalar (const std::string_view& name, const Scalar& v) { operator[](name) = v; }
    void array  (const std::string_view& name, const Array&  v) { operator[](name) = v; }
    void hash   (const std::string_view& name, const Hash&   v) { operator[](name) = v; }
    void sub    (const std::string_view& name, const Sub&    v) { operator[](name) = v; }

    Sub method (const Sv& name) const {
        GV* gv = gv_fetchmeth_sv((HV*)sv, name, 0, 0);
        return gv ? Sub(GvCV(gv)) : Sub();
    }

    Sub method (const std::string_view& name) const {
        GV* gv = gv_fetchmeth_pvn((HV*)sv, name.data(), name.length(), 0, 0);
        return gv ? Sub(GvCV(gv)) : Sub();
    }

    Sub method_strict (const Sv& name) const {
        Sub ret = method(name);
        if (!ret) _throw_nomethod(name);
        return ret;
    }

    Sub method_strict (const std::string_view& name) const {
        Sub ret = method(name);
        if (!ret) _throw_nomethod(name);
        return ret;
    }

    Sub next_method        (const Sub& current) const { return xs::next::method(aTHX_ (HV*)sv, current.get<CV>()); }
    Sub next_method_strict (const Sub& current) const { return xs::next::method_strict(aTHX_ (HV*)sv, current.get<CV>()); }

    Sub super_method        (const Sub& current) const { return xs::super::method(aTHX_ (HV*)sv, current.get<CV>()); }
    Sub super_method_strict (const Sub& current) const { return xs::super::method_strict(aTHX_ (HV*)sv, current.get<CV>()); }

    void mark_as_loaded (const Stash& source)            const;
    void mark_as_loaded (const std::string_view& source) const { mark_as_loaded(Stash(source, GV_ADD)); }

    void inherit        (const Stash& parent);
    void inherit        (const std::string_view& parent) { inherit(Stash(parent, GV_ADD)); }

    bool isa (const std::string_view& parent, U32 hash = 0, int flags = 0) const;
    bool isa (HEK* hek)            const { return isa(std::string_view(HEK_KEY(hek), HEK_LEN(hek)), HEK_HASH(hek), HEK_UTF8(hek)); }
    bool isa (const Stash& parent) const { return isa(HvNAME_HEK(parent.get<HV>())); }

    CallProxy call (const Sv& name)                                                const { return CallProxy(method_strict(name), name_sv()); }
    CallProxy call (const std::string_view& name)                                  const { return CallProxy(method_strict(name), name_sv()); }
    CallProxy call (const Sv& name,               const Scalar& arg)               const { return CallProxy(method_strict(name), name_sv(), &arg, 1); }
    CallProxy call (const std::string_view& name, const Scalar& arg)               const { return CallProxy(method_strict(name), name_sv(), &arg, 1); }
    CallProxy call (const Sv& name,               SV*const* args, size_t items)    const { return CallProxy(method_strict(name), name_sv(), args, items); }
    CallProxy call (const std::string_view& name, SV*const* args, size_t items)    const { return CallProxy(method_strict(name), name_sv(), args, items); }
    CallProxy call (const Sv& name,               std::initializer_list<Scalar> l) const { return CallProxy(method_strict(name), name_sv(), l.begin(), l.size()); }
    CallProxy call (const std::string_view& name, std::initializer_list<Scalar> l) const { return CallProxy(method_strict(name), name_sv(), l.begin(), l.size()); }

    CallProxy call_SUPER (const Sub& current)                                  const { return CallProxy(current.SUPER_strict(), name_sv()); }
    CallProxy call_SUPER (const Sub& current, const Scalar& arg)               const { return CallProxy(current.SUPER_strict(), name_sv(), &arg, 1); }
    CallProxy call_SUPER (const Sub& current, SV*const* args, size_t items)    const { return CallProxy(current.SUPER_strict(), name_sv(), args, items); }
    CallProxy call_SUPER (const Sub& current, std::initializer_list<Scalar> l) const { return CallProxy(current.SUPER_strict(), name_sv(), l.begin(), l.size()); }

    CallProxy call_next (const Sub& current)                                  const { return CallProxy(next_method_strict(current), name_sv()); }
    CallProxy call_next (const Sub& current, const Scalar& arg)               const { return CallProxy(next_method_strict(current), name_sv(), &arg, 1); }
    CallProxy call_next (const Sub& current, SV*const* args, size_t items)    const { return CallProxy(next_method_strict(current), name_sv(), args, items); }
    CallProxy call_next (const Sub& current, std::initializer_list<Scalar> l) const { return CallProxy(next_method_strict(current), name_sv(), l.begin(), l.size()); }

    CallProxy call_next_maybe (const Sub& current)                                  const { return CallProxy(next_method(current), name_sv()); }
    CallProxy call_next_maybe (const Sub& current, const Scalar& arg)               const { return CallProxy(next_method(current), name_sv(), &arg, 1); }
    CallProxy call_next_maybe (const Sub& current, SV*const* args, size_t items)    const { return CallProxy(next_method(current), name_sv(), args, items); }
    CallProxy call_next_maybe (const Sub& current, std::initializer_list<Scalar> l) const { return CallProxy(next_method(current), name_sv(), l.begin(), l.size()); }

    CallProxy call_super (const Sub& current)                                  const { return CallProxy(super_method_strict(current), name_sv()); }
    CallProxy call_super (const Sub& current, const Scalar& arg)               const { return CallProxy(super_method_strict(current), name_sv(), &arg, 1); }
    CallProxy call_super (const Sub& current, SV*const* args, size_t items)    const { return CallProxy(super_method_strict(current), name_sv(), args, items); }
    CallProxy call_super (const Sub& current, std::initializer_list<Scalar> l) const { return CallProxy(super_method_strict(current), name_sv(), l.begin(), l.size()); }

    CallProxy call_super_maybe (const Sub& current)                                  const { return CallProxy(super_method(current), name_sv()); }
    CallProxy call_super_maybe (const Sub& current, const Scalar& arg)               const { return CallProxy(super_method(current), name_sv(), &arg, 1); }
    CallProxy call_super_maybe (const Sub& current, SV*const* args, size_t items)    const { return CallProxy(super_method(current), name_sv(), args, items); }
    CallProxy call_super_maybe (const Sub& current, std::initializer_list<Scalar> l) const { return CallProxy(super_method(current), name_sv(), l.begin(), l.size()); }

    Object bless () const;
    Object bless (const Sv& what) const;

    void add_const_sub (const std::string_view& name, const Sv& val);

private:
    mutable Simple _name_sv;

    void _validate () {
        if (!sv) return;
        if (HvNAME(sv)) return;
        if (is_undef()) return reset();
        reset();
        throw std::invalid_argument("wrong SV* type for Stash");
    }

    void _promote (GV* gv, const std::string_view& key) const;

    void _throw_nomethod (const std::string_view&) const;

    void _throw_nomethod (const Sv& name) const {
        std::string_view _name = Simple(name);
        _throw_nomethod(_name);
    }
};

}
