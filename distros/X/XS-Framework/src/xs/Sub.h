#pragma once
#include <xs/Array.h>
#include <xs/Simple.h>
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
    Sub (panda::string_view subname, I32 flags = 0) {
        *this = get_cvn_flags(subname.data(), subname.length(), flags);
    }

    Sub (const Sub& oth) : Sv(oth)            {}
    Sub (Sub&& oth)      : Sv(std::move(oth)) {}
    Sub (const Sv& oth)  : Sv(oth)            { _validate(); }
    Sub (Sv&& oth)       : Sv(std::move(oth)) { _validate(); }

    Sub (const Simple&) = delete;
    Sub (const Array&)  = delete;
    Sub (const Hash&)   = delete;
    Sub (const Glob&)   = delete;

    Sub& operator= (SV* val)        { Sv::operator=(val); _validate(); return *this; }
    Sub& operator= (CV* val)        { Sv::operator=(val); return *this; }
    Sub& operator= (const Sub& oth) { Sv::operator=(oth); return *this; }
    Sub& operator= (Sub&& oth)      { Sv::operator=(std::move(oth)); return *this; }
    Sub& operator= (const Sv& oth)  { return operator=(oth.get()); }
    Sub& operator= (Sv&& oth)       { Sv::operator=(std::move(oth)); _validate(); return *this; }
    Sub& operator= (const Simple&)  = delete;
    Sub& operator= (const Array&)   = delete;
    Sub& operator= (const Hash&)    = delete;
    Sub& operator= (const Glob&)    = delete;

    void set (SV* val) { Sv::operator=(val); }

    operator AV* () const = delete;
    operator HV* () const = delete;
    operator CV* () const { return (CV*)sv; }
    operator GV* () const = delete;

    CV* operator-> () const { return (CV*)sv; }

    template <typename T = SV> panda::enable_if_one_of_t<T,SV,CV>* get () const { return (T*)sv; }

    Stash stash () const;
    Glob  glob  () const;

    panda::string_view name () const {
        GV* gv = CvGV((CV*)sv);
        return panda::string_view(GvNAME(gv), GvNAMELEN(gv));
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

private:
    struct CallArgs {
        SV*           self;
        SV*const*     list;
        const Scalar* scalars;
        size_t        items;
    };

    template <class Enable, class...Ctx> struct CallContext;

public:
    template <class...Ctx> using call_t = decltype(CallContext<void, Ctx...>::call((CV*)nullptr, CallArgs{}));

    template <class...Ctx, class...Args>
    call_t<Ctx...> call (Args&&...va) const {
        auto args = _get_args(va...);
        return CallContext<void, Ctx...>::call((CV*)sv, args);
    }

    template <class...Args>
    Scalar operator() (Args&&...args) const { return call<Scalar>(std::forward<Args>(args)...); }

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

    template <class...Args>
    struct VCallArgs : CallArgs {
        SV* list[sizeof...(Args)];
        VCallArgs (Args&&...args) : CallArgs{nullptr, list, nullptr, sizeof...(Args)}, list{std::forward<Args>(args)...} {
            for (auto sv : list)
                if (sv && SvTYPE(sv) > SVt_PVMG && SvTYPE(sv) != SVt_PVGV)
                    throw std::invalid_argument("one of arguments for sub.call() is not a scalar value");
        }
    };

    template <class...T> struct type_pack {};

    static CallArgs _get_args (SV*const* args = nullptr, size_t items = 0)       { return {nullptr,    args,   nullptr,    items}; }
    static CallArgs _get_args (SV* arg0, SV*const* args, size_t items)           { return {   arg0,    args,   nullptr,    items}; }
    static CallArgs _get_args (const Scalar* args, size_t items)                 { return {nullptr, nullptr,      args,    items}; }
    static CallArgs _get_args (SV* arg0, const Scalar* args, size_t items)       { return {   arg0, nullptr,      args,    items}; }
    static CallArgs _get_args (const std::initializer_list<Scalar>& l)           { return {nullptr, nullptr, l.begin(), l.size()}; }
    static CallArgs _get_args (SV* arg0, const std::initializer_list<Scalar>& l) { return {   arg0, nullptr, l.begin(), l.size()}; }

    template <class...Args, typename = type_pack<decltype(Scalar(std::declval<Args>()))...>>
    static VCallArgs<Args...> _get_args (Args&&...args) { return {std::forward<Args>(args)...}; }

    static size_t _call (CV*, I32 flags, const CallArgs&, SV** ret, size_t maxret, AV** avr);
};

template <class...Types>
struct Sub::CallContext<void, std::tuple<Types...>> {
    using type = std::tuple<Types...>;
    static constexpr size_t N = sizeof...(Types);

    static type call (CV* cv, const CallArgs& args) {
        SV* ret[N] = {nullptr};
        _call(cv, G_ARRAY, args, ret, N, nullptr);
        return _make_tuple<type>(ret, std::make_index_sequence<N>());
    }

    template <class T, size_t...Inds>
    static T _make_tuple (SV** svs, std::integer_sequence<size_t, Inds...>) {
        return T(typename std::tuple_element<Inds, T>::type(svs[Inds], Sv::NONE)...);
    }
};

template <class Enable, class...Ret>
struct Sub::CallContext : Sub::CallContext<void, std::tuple<Ret...>> {};

template <class T>
struct Sub::CallContext<enable_if_sv_t<T,void>, T> {
    static T call (CV* cv, const CallArgs& args) {
        SV* ret = NULL;
        _call(cv, G_SCALAR, args, &ret, 1, nullptr);
        return T(ret, Sv::NONE);
    }
};

template <>
struct Sub::CallContext<void> : Sub::CallContext<void, Scalar> {};

template <>
struct Sub::CallContext<void, List> {
    static List call (CV* cv, const CallArgs& args) {
        AV* av = NULL;
        _call(cv, G_ARRAY, args, nullptr, 0, &av);
        return List(av, Sv::NONE);
    }
};

template <>
struct Sub::CallContext<void, void> {
    static void call (CV* cv, const CallArgs& args) { _call(cv, G_VOID, args, nullptr, 0, nullptr); }
};

template <class T, size_t N>
struct Sub::CallContext<enable_if_sv_t<T,void>, std::array<T,N>> {
    using type = std::array<T,N>;
    static type call (CV* cv, const CallArgs& args) {
        SV* svret[N];
        auto nret = _call(cv, G_ARRAY, args, svret, N, nullptr);
        type ret;
        for (size_t i = 0; i < nret; ++i) ret[i] = T(svret[i], Sv::NONE);
        return ret;
    }
};

template <>
struct Sub::CallContext<void, panda::string> {
    static panda::string call (CV* cv, const CallArgs& args) { return CallContext<void, Simple>::call(cv, args).as_string<panda::string>(); }
};

template <class T>
struct Sub::CallContext<panda::enable_if_arithmetic_t<T,void>, T> {
    static T call (CV* cv, const CallArgs& args) { return CallContext<void, Simple>::call(cv, args); }
};

}
