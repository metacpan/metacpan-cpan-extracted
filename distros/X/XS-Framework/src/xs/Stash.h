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
    using string_view = panda::string_view;

    struct op_proxy : Glob {
        op_proxy (SV** ptr) : Glob(), ptr(ptr) { if (ptr) set(*ptr); }

        op_proxy& operator= (SV*);
        op_proxy& operator= (AV* v) { _throw(); slot(v); return *this; }
        op_proxy& operator= (HV* v) { _throw(); slot(v); return *this; }
        op_proxy& operator= (CV* v) { _throw(); slot(v); return *this; }
        op_proxy& operator= (GV*);
        op_proxy& operator= (std::nullptr_t)    { return operator=((SV*)NULL); }
        op_proxy& operator= (const Sv& v)       { return operator=(v.get()); }
        op_proxy& operator= (const Scalar& v)   { _throw(); slot(v); return *this; }
        op_proxy& operator= (const Array& v)    { _throw(); slot(v); return *this; }
        op_proxy& operator= (const Hash& v)     { _throw(); slot(v); return *this; }
        op_proxy& operator= (const Sub& v)      { _throw(); slot(v); return *this; }
        op_proxy& operator= (const Glob& v)     { return operator=(v.get<GV>()); }
        op_proxy& operator= (const op_proxy& v) { return operator=(v.get<GV>()); }

        inline void _throw () { if (!ptr) throw std::logic_error("store: empty object"); }

    private:
        SV** ptr;
    };

    static Stash root () { return PL_defstash; }

    static Stash from_name (SV* fqn, I32 flags = 0) { return gv_stashsv(fqn, flags); }

    Stash (std::nullptr_t = nullptr) {}
    Stash (SV* sv, bool policy = INCREMENT) : Hash(sv, policy) { _validate(); }
    Stash (HV* sv, bool policy = INCREMENT) : Hash(sv, policy) { _validate(); }

    Stash (const string_view& package, I32 flags = 0) {
        *this = gv_stashpvn(package.data(), package.length(), flags);
    }

    Stash (const Stash& oth) : Hash(oth)            {}
    Stash (const Hash&  oth) : Hash(oth)            { _validate(); }
    Stash (const Sv&    oth) : Stash(oth.get())     {}
    Stash (Stash&&      oth) : Hash(std::move(oth)) {}
    Stash (Hash&&       oth) : Hash(std::move(oth)) { _validate(); }
    Stash (Sv&&         oth) : Hash(std::move(oth)) { _validate(); }

    Stash (const Simple&) = delete;
    Stash (const Array&)  = delete;
    Stash (const Sub&)    = delete;
    Stash (const Glob&)   = delete;

    Stash& operator= (SV* val)          { Hash::operator=(val); _validate(); return *this; }
    Stash& operator= (HV* val)          { Hash::operator=(val); _validate(); return *this; }
    Stash& operator= (const Stash& oth) { Hash::operator=(oth); return *this; }
    Stash& operator= (Stash&& oth)      { Hash::operator=(std::move(oth)); return *this; }
    Stash& operator= (const Hash& oth)  { Hash::operator=(oth); _validate(); return *this; }
    Stash& operator= (Hash&& oth)       { Hash::operator=(std::move(oth)); _validate(); return *this; }
    Stash& operator= (const Sv& oth)    { return operator=(oth.get()); }
    Stash& operator= (Sv&& oth)         { Hash::operator=(std::move(oth)); _validate(); return *this; }
    Stash& operator= (const Simple&)    = delete;
    Stash& operator= (const Array&)     = delete;
    Stash& operator= (const Sub&)       = delete;
    Stash& operator= (const Glob&)      = delete;

    using Hash::set;
    void set (HV* val) { Hash::operator=(val); }

    Glob fetch (const string_view& key) const {
        auto elem = Hash::fetch(key);
        _promote(elem.get<GV>(), key);
        return elem.get<GV>();
    }

    Glob at (const string_view& key) const {
        Glob ret = fetch(key);
        if (!ret) throw std::out_of_range("at: no key");
        return ret;
    }

    Glob operator[] (const string_view& key) const { return fetch(key); }

    void store (const string_view& key, SV* v)           { operator[](key) = v; }
    void store (const string_view& key, AV* v)           { operator[](key) = v; }
    void store (const string_view& key, HV* v)           { operator[](key) = v; }
    void store (const string_view& key, CV* v)           { operator[](key) = v; }
    void store (const string_view& key, GV* v)           { operator[](key) = v; }
    void store (const string_view& key, const Sv&     v) { operator[](key) = v; }
    void store (const string_view& key, const Scalar& v) { operator[](key) = v; }
    void store (const string_view& key, const Array&  v) { operator[](key) = v; }
    void store (const string_view& key, const Hash&   v) { operator[](key) = v; }
    void store (const string_view& key, const Sub&    v) { operator[](key) = v; }
    void store (const string_view& key, const Glob&   v) { operator[](key) = v; }

    op_proxy operator[] (const string_view& key) {
        if (!sv) return NULL;
        SV** ref = hv_fetch((HV*)sv, key.data(), key.length(), 1);
        _promote((GV*)*ref, key);
        return ref;
    }

    string_view   name           () const { return string_view(HvNAME(sv), HvNAMELEN(sv)); }
    HEK*          name_hek       () const { return HvNAME_HEK_NN((HV*)sv); }
    const Simple& name_sv        () const { if (!_name_sv) _name_sv = Simple::shared(name_hek()); return _name_sv; }
    string_view   effective_name () const { return string_view(HvENAME(sv), HvENAMELEN(sv)); }
    panda::string path           () const;

    Scalar scalar (const string_view& name) const { return fetch(name).scalar(); }
    Array  array  (const string_view& name) const { return fetch(name).array(); }
    Hash   hash   (const string_view& name) const { return fetch(name).hash(); }
    Sub    sub    (const string_view& name) const { return fetch(name).sub(); }

    void scalar (const string_view& name, const Scalar& v) { operator[](name) = v; }
    void array  (const string_view& name, const Array&  v) { operator[](name) = v; }
    void hash   (const string_view& name, const Hash&   v) { operator[](name) = v; }
    void sub    (const string_view& name, const Sub&    v) { operator[](name) = v; }

    Sub method (const Sv& name) const {
        GV* gv = gv_fetchmeth_sv((HV*)sv, name, 0, 0);
        return gv ? Sub(GvCV(gv)) : Sub();
    }

    Sub method (const string_view& name) const {
        GV* gv = gv_fetchmeth_pvn((HV*)sv, name.data(), name.length(), 0, 0);
        return gv ? Sub(GvCV(gv)) : Sub();
    }

    Sub method_strict (const Sv& name) const {
        Sub ret = method(name);
        if (!ret) _throw_nomethod(name);
        return ret;
    }

    Sub method_strict (const string_view& name) const {
        Sub ret = method(name);
        if (!ret) _throw_nomethod(name);
        return ret;
    }

    Sub next_method        (const Sub& current) const { return xs::next::method(aTHX_ (HV*)sv, current.get<CV>()); }
    Sub next_method_strict (const Sub& current) const { return xs::next::method_strict(aTHX_ (HV*)sv, current.get<CV>()); }

    Sub super_method        (const Sub& current) const { return xs::super::method(aTHX_ (HV*)sv, current.get<CV>()); }
    Sub super_method_strict (const Sub& current) const { return xs::super::method_strict(aTHX_ (HV*)sv, current.get<CV>()); }

    void mark_as_loaded (const Stash& source)       const;
    void mark_as_loaded (const string_view& source) const { mark_as_loaded(Stash(source, GV_ADD)); }

    void inherit (const Stash& parent);
    void inherit (const string_view& parent) { inherit(Stash(parent, GV_ADD)); }

    bool isa (const string_view& parent, U32 hash = 0, int flags = 0) const;
    bool isa (HEK* hek)            const { return isa(string_view(HEK_KEY(hek), HEK_LEN(hek)), HEK_HASH(hek), HEK_UTF8(hek)); }
    bool isa (const Stash& parent) const { return isa(HvNAME_HEK(parent.get<HV>())); }

    template <class...R, class...A> Sub::call_t<R...> call       (const Sv& name,   A&&...args) const { return method_strict(name).call<R...>(name_sv(), std::forward<A>(args)...); }
    template <class...R, class...A> Sub::call_t<R...> call       (string_view name, A&&...args) const { return method_strict(name).call<R...>(name_sv(), std::forward<A>(args)...); }
    template <class...R, class...A> Sub::call_t<R...> call_SUPER (const Sub& ctx,   A&&...args) const { return ctx.SUPER_strict().call<R...>(name_sv(), std::forward<A>(args)...); }
    template <class...R, class...A> Sub::call_t<R...> call_next  (const Sub& ctx,   A&&...args) const { return next_method_strict(ctx).call<R...>(name_sv(), std::forward<A>(args)...); }
    template <class...R, class...A> Sub::call_t<R...> call_super (const Sub& ctx,   A&&...args) const { return super_method_strict(ctx).call<R...>(name_sv(), std::forward<A>(args)...); }

    template <class...R, class...A>
    Sub::call_t<R...> call_next_maybe (const Sub& ctx, A&&...args) const {
        auto sub = next_method(ctx);
        if (!sub) return Sub::call_t<R...>();
        return sub.call<R...>(name_sv(), std::forward<A>(args)...);
    }

    template <class...R, class...A>
    Sub::call_t<R...> call_super_maybe (const Sub& ctx, A&&...args) const {
        auto sub = super_method(ctx);
        if (!sub) return Sub::call_t<R...>();
        return sub.call<R...>(name_sv(), std::forward<A>(args)...);
    }

    Object bless () const;
    Object bless (const Sv& what) const;

    void add_const_sub (const panda::string_view& name, const Sv& val);

private:
    mutable Simple _name_sv;

    void _validate () {
        if (!sv) return;
        if (HvNAME(sv)) return;
        if (is_undef()) return reset();
        reset();
        throw std::invalid_argument("wrong SV* type for Stash");
    }

    void _promote (GV* gv, const panda::string_view& key) const;

    void _throw_nomethod (const panda::string_view&) const;

    void _throw_nomethod (const Sv& name) const {
        panda::string_view _name = Simple(name);
        _throw_nomethod(_name);
    }
};

}
