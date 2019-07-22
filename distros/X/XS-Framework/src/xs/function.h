#pragma once
#include "typemap.h"
#include <tuple>
#include <utility>
#include <panda/cast.h>
#include <panda/function.h>

namespace xs { namespace func {

using panda::function;
using panda::dyn_cast;

extern Sv::payload_marker_t marker;

template <class T, class F>
struct ConverterIn {
    using type = T;
    F f;
    ConverterIn (const F& f) : f(f) {}
    ConverterIn (F&& f)      : f(std::move(f)) {}
    decltype(std::declval<F>()(Sv())) in (const Sv& sv) { return f(sv); }
};

template <class T>
struct ConverterIn<T, std::nullptr_t> {
    using type = T;
    ConverterIn (std::nullptr_t) {}
    decltype(xs::in<T>(Sv())) in (const Sv& sv) { return xs::in<T>(sv); }
};

template <>
struct ConverterIn<void, std::nullptr_t> {
    using type = void;
    ConverterIn (std::nullptr_t) {}
    void in (const Sv&) {}
};

template <class T, class F>
struct ConverterOut {
    using type = T;
    F f;
    ConverterOut (const F& f) : f(f) {}
    ConverterOut (F&& f)      : f(std::move(f)) {}
    Sv out (const T& val) { return f(val); }
};

template <class T>
struct ConverterOut<T, std::nullptr_t> {
    using type = T;
    ConverterOut (std::nullptr_t) {}
    Sv out (const T& val) { return xs::out<T>(val); }
};

template <>
struct ConverterOut<void, std::nullptr_t> {
    using type = void;
    ConverterOut (std::nullptr_t) {}
    Sv out () { return {}; }
};

template <typename Ret, typename...Args>
struct SubHolder : panda::Ifunction<Ret, Args...> {
    Sub sub;
    SubHolder (const Sub& sub) : sub(sub) {}

    bool equals (const panda::function_details::AnyFunction* oth) const override {
        auto oth_caller = dyn_cast<const SubHolder*>(oth);
        return oth_caller && this->sub == oth_caller->sub;
    }
};

template <typename Ret, typename...Args>
struct SubCallerComparator : SubHolder<Ret, Args...> {
    using SubHolder<Ret, Args...>::SubHolder;
    Ret operator() (Args...) override { throw "should not be called"; }
};

template <typename RetConv, typename...Convs>
struct SubCaller : SubHolder<typename RetConv::type, typename Convs::type...> {
    using Ret   = typename RetConv::type;
    using Super = SubHolder<Ret, typename Convs::type...>;
    using Tuple = std::tuple<Convs...>;

    template <class RetConvArg, class...ConvArgs>
    SubCaller (const Sub& sub, RetConvArg&& rcarg, ConvArgs&&...cargs)
        : Super(sub), ret_conv(RetConv{std::forward<RetConvArg>(rcarg)}), arg_convs(Convs{std::forward<ConvArgs>(cargs)}...) {}

    SubCaller (const Sub& sub, const RetConv& rc, const Convs&...acs) : Super(sub), ret_conv(rc), arg_convs(acs...) {}

    Ret operator() (typename Convs::type... args) override {
        constexpr size_t ARGS_COUNT = sizeof...(Convs);
        SV* sv_args[ARGS_COUNT];
        push(sv_args, args...);
        return call_impl(sv_args, ARGS_COUNT, typename std::is_void<Ret>::type());
    }

private:
    RetConv ret_conv;
    Tuple   arg_convs;

    template <size_t pos = 0>
    void push (SV**) {}

    template <size_t pos = 0, typename First, typename...Others>
    void push (SV** dest, First&& f, Others&&...oths) {
        dest[pos] = std::get<pos>(arg_convs).out(std::forward<First>(f)).detach();
        push<pos+1>(dest, std::forward<Others>(oths)...);
    }

    Ret call_impl (SV** args, size_t items, std::false_type) {
        Scalar ret = this->sub.call(args, items);
        for (size_t i = 0; i < items; ++i) SvREFCNT_dec(args[i]);
        return ret_conv.in(ret ? ret : Scalar::undef);
    }

    Ret call_impl (SV** args, size_t items, std::true_type) {
        this->sub.template call<void>(args, items);
        for (size_t i = 0; i < items; ++i) SvREFCNT_dec(args[i]);
    }
};

struct IFunctionCaller {
    virtual Sv call (SV**, size_t) = 0;
    virtual ~IFunctionCaller () {}
};

template <typename Ret, typename...Args>
struct FunctionHolder : IFunctionCaller {
    using Func = panda::function<Ret(Args...)>;
    Func func;
    FunctionHolder (const Func& f) : func(f) {}
};

template <typename RetConv, typename...Convs>
struct FunctionCaller : FunctionHolder<typename RetConv::type, typename Convs::type...> {
    using Ret   = typename RetConv::type;
    using Super = FunctionHolder<Ret, typename Convs::type...>;
    using Func  = typename Super::Func;
    using Tuple = std::tuple<Convs...>;

    template <class RetConvArg, class...ConvArgs>
    FunctionCaller (const Func& f, RetConvArg&& rcarg, ConvArgs&&...cargs)
        : Super(f), ret_conv(RetConv{std::forward<RetConvArg>(rcarg)}), arg_convs(Convs{std::forward<ConvArgs>(cargs)}...) {}

    FunctionCaller (const Func& f, const RetConv& rc, const Convs&...acs) : Super(f), ret_conv(rc), arg_convs(acs...) {}

    Sv call (SV** svs, size_t items) override {
        constexpr size_t ARGS_COUNT = sizeof...(Convs);
        if (items != ARGS_COUNT) throw Simple::format("wrong number of arguments for subroutine call: expected %d, passed %d", ARGS_COUNT, items);
        return call_impl(svs, std::make_index_sequence<ARGS_COUNT>(), typename std::is_void<Ret>::type());
    }

private:
    RetConv ret_conv;
    Tuple   arg_convs;

    template <size_t...Inds>
    Sv call_impl (SV** svs, std::index_sequence<Inds...>, std::false_type) {
        auto args = std::make_tuple(std::get<Inds>(arg_convs).in(svs[Inds])...); // proxy on stack to be able to pass non-const references
        (void)args; // supress warning when no input args
        return ret_conv.out(this->func(std::get<Inds>(args)...));
    }

    template <size_t... Inds>
    Sv call_impl (SV** svs, std::index_sequence<Inds...>, std::true_type) {
        auto args = std::make_tuple(std::get<Inds>(arg_convs).in(svs[Inds])...);
        (void)args;
        this->func(std::get<Inds>(args)...);
        return {};
    }
};

template <int N, class R, class F, class...Args>
std::enable_if_t<(sizeof...(Args) == N), R>
fill_default_args (const F& f, Args&&... args) {
    return f(std::forward<Args>(args)...);
}

template <int N, class R, class F, class...Args>
std::enable_if_t<(sizeof...(Args) < N), R>
fill_default_args (const F& f, Args&&... args) {
    return fill_default_args<N, R>(f, std::forward<Args>(args)..., nullptr);
}

template <typename Ret, typename...Args, typename...ConvArgs>
panda::iptr<panda::Ifunction<Ret, Args...>> sub2function_impl (const Sub& sub, ConvArgs&&...cargs) {
    return fill_default_args<sizeof...(Args) + 1, panda::Ifunction<Ret, Args...>*>([&](auto&& rcarg, auto&&...cargs) {
        return new SubCaller<ConverterIn<Ret, std::decay_t<decltype(rcarg)>>, ConverterOut<Args, std::decay_t<decltype(cargs)>>...>(
            sub, std::forward<decltype(rcarg)>(rcarg), std::forward<decltype(cargs)>(cargs)...
        );
    }, std::forward<ConvArgs>(cargs)...);
}

template <typename Ret, typename...Args, typename...ConvArgs>
IFunctionCaller* function2sub_impl (const panda::function<Ret(Args...)>& f, ConvArgs&&...cargs) {
    return fill_default_args<sizeof...(Args) + 1, IFunctionCaller*>([&](auto&& rcarg, auto&&...cargs) {
        return new FunctionCaller<ConverterOut<Ret, std::decay_t<decltype(rcarg)>>, ConverterIn<Args, std::decay_t<decltype(cargs)>>...>(
            f, std::forward<decltype(rcarg)>(rcarg), std::forward<decltype(cargs)>(cargs)...
        );
    }, std::forward<ConvArgs>(cargs)...);
}

template <typename Ret, typename...Args, typename...ConvArgs>
std::enable_if_t<std::is_void<Ret>::value, panda::function<Ret(Args...)>>
sub2function (panda::function<Ret(Args...)>*, const Sub& sub, ConvArgs&&...cargs) {
    auto fc = reinterpret_cast<IFunctionCaller*>(sub.payload(&marker).ptr);
    if (auto holder = dyn_cast<FunctionHolder<Ret, Args...>*>(fc)) return holder->func;
    return sub2function_impl<Ret, Args...>(sub, nullptr, std::forward<ConvArgs>(cargs)...);
}

template <typename Ret, typename...Args, typename...ConvArgs>
std::enable_if_t<!std::is_void<Ret>::value, panda::function<Ret(Args...)>>
sub2function (panda::function<Ret(Args...)>*, const Sub& sub, ConvArgs&&...cargs) {
    auto fc = reinterpret_cast<IFunctionCaller*>(sub.payload(&marker).ptr);
    if (auto holder = dyn_cast<FunctionHolder<Ret, Args...>*>(fc)) return holder->func;
    return sub2function_impl<Ret, Args...>(sub, std::forward<ConvArgs>(cargs)...);
}

template <typename Ret, typename...Args, typename...ConvArgs>
std::enable_if_t<std::is_void<Ret>::value, IFunctionCaller*>
function2sub (const panda::function<Ret(Args...)>& f, ConvArgs&&...cargs) {
    return function2sub_impl(f, nullptr, std::forward<ConvArgs>(cargs)...);
}

template <typename Ret, typename...Args, typename...ConvArgs>
std::enable_if_t<!std::is_void<Ret>::value, IFunctionCaller*>
function2sub (const panda::function<Ret(Args...)>& f, ConvArgs&&...cargs) {
    return function2sub_impl(f, std::forward<ConvArgs>(cargs)...);
}

Sub create_sub (IFunctionCaller*);


// sub2function low-level interface (used by CallbackDispatcher)
template <typename RetConv, typename...Convs>
panda::iptr<panda::Ifunction<typename std::decay_t<RetConv>::type, typename std::decay_t<Convs>::type...>>
sub2function_with_convs (const Sub& sub, RetConv&& rc, Convs&&...acs) {
    return new SubCaller<std::decay_t<RetConv>, std::decay_t<Convs>...>(sub, std::forward<RetConv>(rc), std::forward<Convs>(acs)...);
}

// function2sub low-level interface (used by CallbackDispatcher)
template <typename RetConv, typename...Convs>
Sub function2sub_with_convs (const panda::function<typename std::decay_t<RetConv>::type(typename std::decay_t<Convs>::type...)>& f, RetConv&& rc, Convs&&...acs) {
    auto fc = new FunctionCaller<std::decay_t<RetConv>, std::decay_t<Convs>...>(f, std::forward<RetConv>(rc), std::forward<Convs>(acs)...);
    return create_sub(fc);
}

}}

namespace xs {
    template <typename F, typename...ConvArgs>
    std::enable_if_t<std::is_function<F>::value, panda::function<F>>
    sub2function (const Sub& sub, ConvArgs&&...cargs) {
        if (!sub) return {};
        return xs::func::sub2function((panda::function<F>*)(nullptr), sub, std::forward<ConvArgs>(cargs)...);
    }

    template <typename F, typename...ConvArgs>
    std::enable_if_t<!std::is_function<F>::value, F>
    sub2function (const Sub& sub, ConvArgs&&...cargs) {
        if (!sub) return {};
        return xs::func::sub2function((F*)(nullptr), sub, std::forward<ConvArgs>(cargs)...);
    }

    template <class Ret, class...Args, class...ConvArgs>
    Sub function2sub (const panda::function<Ret(Args...)>& f, ConvArgs&&...cargs) {
        if (!f) return {};
        auto caller = panda::dyn_cast<xs::func::SubHolder<Ret, Args...>*>(f.func.get());
        if (caller) return caller->sub;
        return xs::func::create_sub(xs::func::function2sub(f, std::forward<ConvArgs>(cargs)...));
    }

    template <typename Ret, typename... Args>
    struct Typemap<panda::function<Ret(Args...)>> : TypemapBase<panda::function<Ret(Args...)>> {
        using Func = panda::function<Ret(Args...)>;

        static inline Func in (pTHX_ const Sub& sub) {
            return sub2function<Ret(Args...)>(sub);
        }

        static inline Sv out (pTHX_ const Func& f, const Sv& = {}) {
            if (!f) return Sv::undef;
            return Ref::create(function2sub(f));
        }
    };
}
