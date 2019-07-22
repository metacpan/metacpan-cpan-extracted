#pragma once
#include <xs/Sv.h>
#include <xs/Sub.h>
#include <xs/Ref.h>
#include <xs/next.h>
#include <xs/Stash.h>

namespace xs {

struct Stash;

struct Object : Sv {
    using string_view = panda::string_view;

    Object (std::nullptr_t = nullptr) {}

    template <class T, typename = panda::enable_if_one_of_t<T,SV,AV,HV,CV,GV>>
    Object (T* sv, bool policy = INCREMENT) : Sv(sv, policy) { _validate(); }

    Object (const Object& oth) : Sv(oth), _ref(oth._ref)                       {}
    Object (Object&&      oth) : Sv(std::move(oth)), _ref(std::move(oth._ref)) {}
    Object (const Sv&     oth) : Sv(oth)                                       { _validate(); }
    Object (Sv&&          oth) : Sv(std::move(oth))                            { _validate(); }

    template <class T, typename = panda::enable_if_one_of_t<T,SV,AV,HV,CV,GV>>
    Object& operator= (T* val)            { _ref.reset(); Sv::operator=(val); _validate(); return *this; }
    Object& operator= (const Object& oth) { Sv::operator=(oth); _ref = oth._ref; return *this; }
    Object& operator= (Object&& oth)      { Sv::operator=(std::move(oth)); _ref = std::move(oth._ref); return *this; }
    Object& operator= (const Sv& oth)     { _ref.reset(); Sv::operator=(oth); _validate(); return *this; }
    Object& operator= (Sv&& oth)          { _ref.reset(); Sv::operator=(std::move(oth)); _validate(); return *this; }

    template <class T, typename = panda::enable_if_one_of_t<T,SV,AV,HV,CV,GV>>
    void set (T* val) { _ref.reset(); Sv::operator=(val); }

    Stash stash () const { return SvSTASH(sv); }

    void stash (const Stash&);

    const Ref& ref () const { _check_ref(); return _ref; }

    void rebless (const Stash& stash);

    Sub method        (const Sv& name) const;
    Sub method        (const string_view& name) const;
    Sub method_strict (const Sv& name) const;
    Sub method_strict (const string_view& name) const;

    Sub next_method        (const Sub& current) const { return xs::next::method(aTHX_ stash(), current.get<CV>()); }
    Sub next_method_strict (const Sub& current) const { return xs::next::method_strict(aTHX_ stash(), current.get<CV>()); }

    Sub super_method        (const Sub& current) const { return xs::super::method(aTHX_ stash(), current.get<CV>()); }
    Sub super_method_strict (const Sub& current) const { return xs::super::method_strict(aTHX_ stash(), current.get<CV>()); }

    bool isa (const string_view& parent) {  _check_ref(); return sv_derived_from_pvn(_ref, parent.data(), parent.length(), 0); }
    bool isa (const Stash& parent)       { return isa(parent.name()); }

    template <class...R, class...A> Sub::call_t<R...> call       (const Sv& name,   A&&...args) const { _check_ref(); return method_strict(name).call<R...>(_ref, std::forward<A>(args)...); }
    template <class...R, class...A> Sub::call_t<R...> call       (string_view name, A&&...args) const { _check_ref(); return method_strict(name).call<R...>(_ref, std::forward<A>(args)...); }
    template <class...R, class...A> Sub::call_t<R...> call_SUPER (const Sub& ctx,   A&&...args) const { return ctx.SUPER_strict().call<R...>(_ref, std::forward<A>(args)...); }
    template <class...R, class...A> Sub::call_t<R...> call_next  (const Sub& ctx,   A&&...args) const { return next_method_strict(ctx).call<R...>(_ref, std::forward<A>(args)...); }
    template <class...R, class...A> Sub::call_t<R...> call_super (const Sub& ctx,   A&&...args) const { return super_method_strict(ctx).call<R...>(_ref, std::forward<A>(args)...); }

    template <class...R, class...A>
    Sub::call_t<R...> call_next_maybe (const Sub& ctx, A&&...args) const {
        auto sub = next_method(ctx);
        if (!sub) return Sub::call_t<R...>();
        return sub.call<R...>(_ref, std::forward<A>(args)...);
    }

    template <class...R, class...A>
    Sub::call_t<R...> call_super_maybe (const Sub& ctx, A&&...args) const {
        auto sub = super_method(ctx);
        if (!sub) return Sub::call_t<R...>();
        return sub.call<R...>(_ref, std::forward<A>(args)...);
    }

    void reset () { _ref.reset(); Sv::reset(); }

    SV* detach () {
        _ref.reset();
        return Sv::detach();
    }

private:
    mutable Ref _ref;

    void _validate () {
        if (!sv) return;
        if (SvOBJECT(sv)) return;
        if (SvROK(sv)) {           // reference to object?
            SV* val = SvRV(sv);
            if (SvOBJECT(val)) {
                _ref = sv;
                Sv::operator=(val);
                return;
            }
        }
        if (is_undef()) return reset();
        reset();
        throw std::invalid_argument("wrong SV* type for Object");
    }

    void _check_ref () const { if (!_ref || SvRV(_ref) != sv) _ref = Ref::create(sv); }
};

}
