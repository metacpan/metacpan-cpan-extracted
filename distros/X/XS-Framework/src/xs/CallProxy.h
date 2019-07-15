#pragma once
#include <xs/basic.h>
#include <array>
#include <vector>
#include <panda/string.h>
#include <panda/string_view.h>
#include <panda/lib/integer_sequence.h>

namespace xs {

struct Sv;
struct Ref;
struct Array;
struct Scalar;
struct Simple;
struct Object;
using xs::my_perl;

namespace {
    constexpr bool __or (bool b) { return b; }
    template <class...Args> constexpr bool __or (bool b, Args... args) { return b || __or(args...); }
    template <class T, class... Args> using one_of_t = typename std::enable_if<__or(std::is_same<T,Args>::value...), T>::type;
}

struct CallProxy {
    CallProxy (CV* cv, SV* arg = NULL, SV*const* args = NULL, size_t items = 0)
        : cv(cv), arg(arg), sv_args(args), args(NULL), items(items), called(false) {}

    CallProxy (CV* cv, SV* arg, const Scalar* args, size_t items)
        : cv(cv), arg(arg), sv_args(NULL), args(args), items(items), called(false) {}

    template <class T, size_t N, typename = one_of_t<T,Sv,Scalar,Ref,Simple>>
    operator std::array<T,N> () {
        SV* svret[N];
        auto nret = _call(G_ARRAY, svret, N, NULL);
        std::array<T,N> ret;
        for (U32 i = 0; i < nret; ++i) ret[i] = T(svret[i], false);
        return ret;
    }

    template <class... Types>
    operator std::tuple<Types...> () {
        SV* svret[sizeof...(Types)] = {nullptr};
        _call(G_ARRAY, svret, sizeof...(Types), NULL);
        return _make_tuple<std::tuple<Types...>>(svret, std::make_integer_sequence<size_t, sizeof...(Types)>());
    }

    Scalar scalar () const;
    Array  list   () const;

    CallProxy call (const std::string_view& name);
    CallProxy call (const std::string_view& name, const Scalar& arg);
    CallProxy call (const std::string_view& name, SV*const* args, size_t items);
    CallProxy call (const std::string_view& name, std::initializer_list<Scalar> l);

    template <class T = panda::string> T as_string () const;

    template <class T = int> T as_number () const;

    ~CallProxy () noexcept(false) {
        if (called) return;
        _call(G_VOID, NULL, 0, NULL);
    }
private:
    CV*       cv;
    SV*       arg;
    SV*const* sv_args;
    const Scalar*   args;
    size_t    items;
    mutable bool called;

    size_t _call (I32 flags, SV** ret, size_t maxret, AV** avr) const;

    template <class T, size_t... Inds>
    T _make_tuple (SV** svs, std::integer_sequence<size_t, Inds...>) { return T( typename std::tuple_element<Inds, T>::type(svs[Inds], false)... ); }

    Sv sv () const;

    friend struct Sv;
    friend struct Sub;
    friend struct Glob;
    friend struct Hash;
    friend struct Array;
    friend struct Stash;
    friend struct Object;
};

}
