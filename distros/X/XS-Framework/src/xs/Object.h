#pragma once
#include <xs/Sv.h>
#include <xs/Sub.h>
#include <xs/Ref.h>
#include <xs/next.h>
#include <xs/Stash.h>

namespace xs {

struct Stash;

struct Object : Sv {

    Object (std::nullptr_t = nullptr) {}

    template <class T, typename = one_of_t<T,SV,AV,HV,CV,GV>>
    Object (T* sv, bool policy = INCREMENT) : Sv(sv, policy) { _validate(); }

    Object (const Object& oth) : Sv(oth), _ref(oth._ref)                       {}
    Object (Object&&      oth) : Sv(std::move(oth)), _ref(std::move(oth._ref)) {}
    Object (const Sv&     oth) : Sv(oth)                                       { _validate(); }
    Object (Sv&&          oth) : Sv(std::move(oth))                            { _validate(); }

    Object (const CallProxy& p) : Object(p.sv()) {}

    template <class T, typename = one_of_t<T,SV,AV,HV,CV,GV>>
    Object& operator= (T* val)             { _ref.reset(); Sv::operator=(val); _validate(); return *this; }
    Object& operator= (const Object& oth)  { Sv::operator=(oth); _ref = oth._ref; return *this; }
    Object& operator= (Object&& oth)       { Sv::operator=(std::move(oth)); _ref = std::move(oth._ref); return *this; }
    Object& operator= (const Sv& oth)      { _ref.reset(); Sv::operator=(oth); _validate(); return *this; }
    Object& operator= (Sv&& oth)           { _ref.reset(); Sv::operator=(std::move(oth)); _validate(); return *this; }
    Object& operator= (const CallProxy& p) { return operator=(p.sv()); }

    template <class T, typename = one_of_t<T,SV,AV,HV,CV,GV>>
    void set (T* val) { _ref.reset(); Sv::operator=(val); }

    Stash stash () const { return SvSTASH(sv); }

    void stash (const Stash&);

    const Ref& ref () const { _check_ref(); return _ref; }

    void rebless (const Stash& stash);

    Sub method        (const Sv& name) const;
    Sub method        (const std::string_view& name) const;
    Sub method_strict (const Sv& name) const;
    Sub method_strict (const std::string_view& name) const;

    Sub next_method        (const Sub& current) const { return xs::next::method(aTHX_ stash(), current.get<CV>()); }
    Sub next_method_strict (const Sub& current) const { return xs::next::method_strict(aTHX_ stash(), current.get<CV>()); }

    Sub super_method        (const Sub& current) const { return xs::super::method(aTHX_ stash(), current.get<CV>()); }
    Sub super_method_strict (const Sub& current) const { return xs::super::method_strict(aTHX_ stash(), current.get<CV>()); }

    bool isa (const std::string_view& parent) {  _check_ref(); return sv_derived_from_pvn(_ref, parent.data(), parent.length(), 0); }
    bool isa (const Stash& parent)            { return isa(parent.name()); }

    CallProxy call (const Sv& name)                                                const { _check_ref(); return CallProxy(method_strict(name), _ref); }
    CallProxy call (const std::string_view& name)                                  const { _check_ref(); return CallProxy(method_strict(name), _ref); }
    CallProxy call (const Sv& name,               const Scalar& arg)               const { _check_ref(); return CallProxy(method_strict(name), _ref, &arg, 1); }
    CallProxy call (const std::string_view& name, const Scalar& arg)               const { _check_ref(); return CallProxy(method_strict(name), _ref, &arg, 1); }
    CallProxy call (const Sv& name,               SV*const* args, size_t items)    const { _check_ref(); return CallProxy(method_strict(name), _ref, args, items); }
    CallProxy call (const std::string_view& name, SV*const* args, size_t items)    const { _check_ref(); return CallProxy(method_strict(name), _ref, args, items); }
    CallProxy call (const Sv& name,               std::initializer_list<Scalar> l) const { _check_ref(); return CallProxy(method_strict(name), _ref, l.begin(), l.size()); }
    CallProxy call (const std::string_view& name, std::initializer_list<Scalar> l) const { _check_ref(); return CallProxy(method_strict(name), _ref, l.begin(), l.size()); }

    CallProxy call_SUPER (const Sub& current)                                  const { return CallProxy(current.SUPER_strict(), _ref); }
    CallProxy call_SUPER (const Sub& current, const Scalar& arg)               const { return CallProxy(current.SUPER_strict(), _ref, &arg, 1); }
    CallProxy call_SUPER (const Sub& current, SV*const* args, size_t items)    const { return CallProxy(current.SUPER_strict(), _ref, args, items); }
    CallProxy call_SUPER (const Sub& current, std::initializer_list<Scalar> l) const { return CallProxy(current.SUPER_strict(), _ref, l.begin(), l.size()); }

    CallProxy call_next (const Sub& current)                                  const { return CallProxy(next_method_strict(current), _ref); }
    CallProxy call_next (const Sub& current, const Scalar& arg)               const { return CallProxy(next_method_strict(current), _ref, &arg, 1); }
    CallProxy call_next (const Sub& current, SV*const* args, size_t items)    const { return CallProxy(next_method_strict(current), _ref, args, items); }
    CallProxy call_next (const Sub& current, std::initializer_list<Scalar> l) const { return CallProxy(next_method_strict(current), _ref, l.begin(), l.size()); }

    CallProxy call_next_maybe (const Sub& current)                                  const { return CallProxy(next_method(current), _ref); }
    CallProxy call_next_maybe (const Sub& current, const Scalar& arg)               const { return CallProxy(next_method(current), _ref, &arg, 1); }
    CallProxy call_next_maybe (const Sub& current, SV*const* args, size_t items)    const { return CallProxy(next_method(current), _ref, args, items); }
    CallProxy call_next_maybe (const Sub& current, std::initializer_list<Scalar> l) const { return CallProxy(next_method(current), _ref, l.begin(), l.size()); }

    CallProxy call_super (const Sub& current)                                  const { return CallProxy(super_method_strict(current), _ref); }
    CallProxy call_super (const Sub& current, const Scalar& arg)               const { return CallProxy(super_method_strict(current), _ref, &arg, 1); }
    CallProxy call_super (const Sub& current, SV*const* args, size_t items)    const { return CallProxy(super_method_strict(current), _ref, args, items); }
    CallProxy call_super (const Sub& current, std::initializer_list<Scalar> l) const { return CallProxy(super_method_strict(current), _ref, l.begin(), l.size()); }

    CallProxy call_super_maybe (const Sub& current)                                  const { return CallProxy(super_method(current), _ref); }
    CallProxy call_super_maybe (const Sub& current, const Scalar& arg)               const { return CallProxy(super_method(current), _ref, &arg, 1); }
    CallProxy call_super_maybe (const Sub& current, SV*const* args, size_t items)    const { return CallProxy(super_method(current), _ref, args, items); }
    CallProxy call_super_maybe (const Sub& current, std::initializer_list<Scalar> l) const { return CallProxy(super_method(current), _ref, l.begin(), l.size()); }

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
