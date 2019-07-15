#pragma once
#include "function.h"
#include <tuple>
#include <utility>
#include <panda/CallbackDispatcher.h>

namespace xs { namespace callback_dispatcher {
    using panda::function;
    using panda::CallbackDispatcher;
    using xs::func::ConverterIn;
    using xs::func::ConverterOut;

    struct XSCallbackDispatcher {
        virtual ~XSCallbackDispatcher () {}

        virtual void add                   (const Sub& cv, bool = false) = 0;
        virtual void add_event_listener    (const Sub& cv, bool = false) = 0;
        virtual void remove                (const Sub& cv)               = 0;
        virtual void remove_event_listener (const Sub& cv)               = 0;
        virtual Sv   call                  (SV** args, size_t items)     = 0;
        virtual void remove_all            ()                            = 0;
        virtual bool has_listeners         ()                            = 0;

        void add_back                (const Sub& cv) { add(cv, true); }
        void add_event_listener_back (const Sub& cv) { add_event_listener(cv, true); }

        template <typename Ret, class...Args, class...Rest>
        static XSCallbackDispatcher* create (CallbackDispatcher<Ret(Args...)>&, Rest&&...);
    };

    template <class T, class OutArg, class InArg, typename OutF = std::decay_t<OutArg>, typename InF = std::decay_t<InArg>>
    std::pair<ConverterOut<T, OutF>, ConverterIn<T, InF>> create_converter_pair (const std::pair<OutArg, InArg>& p) {
        return { ConverterOut<T, OutF>(p.first), ConverterIn<T, InF>(p.second) };
    }

    template <class T, class OutArg, class InArg, typename OutF = std::decay_t<OutArg>, typename InF = std::decay_t<InArg>>
    std::pair<ConverterOut<T, OutF>, ConverterIn<T, InF>> create_converter_pair (std::pair<OutArg, InArg>& p) {
        return { ConverterOut<T, OutF>(p.first), ConverterIn<T, InF>(p.second) };
    }

    template <class T, class OutArg, class InArg, typename OutF = std::decay_t<OutArg>, typename InF = std::decay_t<InArg>>
    std::pair<ConverterOut<T, OutF>, ConverterIn<T, InF>> create_converter_pair (std::pair<OutArg, InArg>&& p) {
        return { ConverterOut<T, OutF>(std::move(p.first)), ConverterIn<T, InF>(std::move(p.second)) };
    }

    template <class T, class OutArg, typename OutF = std::decay_t<OutArg>>
    std::pair<ConverterOut<T, OutF>, ConverterIn<T, std::nullptr_t>> create_converter_pair (OutArg&& arg) {
        return { ConverterOut<T, OutF>(std::forward<OutArg>(arg)), ConverterIn<T, std::nullptr_t>(nullptr) };
    }

    template <class Ret, class RetConv, class...Convs>
    struct XSCallbackDispatcherImpl : XSCallbackDispatcher {
        static constexpr size_t ARGS_COUNT = sizeof...(Convs);
        using Dispatcher     = CallbackDispatcher<Ret(typename Convs::first_type::type...)>;
        using Event          = typename Dispatcher::Event;
        using Callback       = typename Dispatcher::Callback;
        using SimpleCallback = typename Dispatcher::SimpleCallback;
        using OptRet         = typename Dispatcher::OptionalRet;
        using Tuple          = std::tuple<Convs...>;
        using Indices        = std::make_index_sequence<ARGS_COUNT>;
        using VoidIn         = ConverterIn<void, std::nullptr_t>;
        using IFuncSimple    = panda::Ifunction<void, typename Convs::first_type::type...>;
        using IFuncExt       = panda::Ifunction<OptRet, Event&, typename Convs::first_type::type...>;

        struct EventOut {
            using type = Event&;
            XSCallbackDispatcherImpl& xsd;

            EventOut (XSCallbackDispatcherImpl& d) : xsd(d) {}

            Sv out (Event& e) { return _out(e, Indices{}); }

            template <std::size_t...I>
            Sv _out (Event& e, std::index_sequence<I...>) {
                Event* ep = &e;
                auto ret = function2sub_with_convs([ep](typename Convs::first_type::type...args) -> OptRet {
                    return ep->next(args...);
                }, xsd.ret_conv.first, std::get<I>(xsd.arg_convs).second...);
                return Ref::create(ret);
            }
        };

        template <class RetConvArg, class...ConvArgs>
        XSCallbackDispatcherImpl (Dispatcher& d, RetConvArg&& rcarg, ConvArgs&&... cargs)
            : dispatcher(d),
              ret_conv(create_converter_pair<OptRet>(std::forward<RetConvArg>(rcarg))),
              arg_convs(create_converter_pair<typename Convs::first_type::type>(std::forward<ConvArgs>(cargs))...)
        {}

        void add (const Sub& sub, bool back) override { _add(sub, back, Indices{}); }

        void add_event_listener (const Sub& sub, bool back) override { _add_event_listener(sub, back, Indices{}); }

        void remove (const Sub& sub) override { _remove(sub, Indices{}); }

        void remove_event_listener (const Sub& sub) override { _remove_event_listener(sub, Indices{}); }

        void remove_all () override {
            dispatcher.remove_all();
        }

        bool has_listeners () override {
            return dispatcher.has_listeners();
        }

        Sv call (SV** svs, size_t items) override {
            if (items != ARGS_COUNT) throw Simple::format("wrong number of arguments for CallbackDispatcher::call(): expected %d, passed %d", ARGS_COUNT, items);
            return call_impl(svs, Indices{}, (Ret*)nullptr);
        }

    private:
        Dispatcher& dispatcher;
        RetConv     ret_conv;
        Tuple       arg_convs;

        template <std::size_t...I>
        void _add (const Sub& sub, bool back, std::index_sequence<I...>) {
            auto f = xs::func::sub2function_with_convs(sub, VoidIn(nullptr), std::get<I>(arg_convs).first...);
            dispatcher.add(SimpleCallback(f), back);
        }

        template <std::size_t...I>
        void _add_event_listener (const Sub& sub, bool back, std::index_sequence<I...>) {
            auto f = xs::func::sub2function_with_convs(sub, ret_conv.second, EventOut(*this), std::get<I>(arg_convs).first...);
            dispatcher.add_event_listener(Callback(f), back);
        }

        template <std::size_t...I>
        void _remove (const Sub& sub, std::index_sequence<I...>) {
            dispatcher.remove(xs::func::SubCallerComparator<void, typename Convs::first_type::type...>(sub));
        }

        template <std::size_t...I>
        void _remove_event_listener (const Sub& sub, std::index_sequence<I...>) {
            dispatcher.remove(xs::func::SubCallerComparator<typename RetConv::second_type::type, Event&, typename Convs::first_type::type...>(sub));
        }

        template <size_t...I, typename _Ret, typename = std::enable_if_t<!std::is_void<_Ret>::value>>
        Sv call_impl (SV** svs, std::index_sequence<I...>, _Ret*) {
            auto args = std::make_tuple(std::get<I>(arg_convs).second.in(svs[I])...);
            (void)args;
            return ret_conv.first.out(dispatcher(std::get<I>(args)...));
        }

        template <size_t...I>
        Sv call_impl (SV** svs, std::index_sequence<I...>, void*) {
            auto args = std::make_tuple(std::get<I>(arg_convs).second.in(svs[I])...);
            (void)args;
            dispatcher(std::get<I>(args)...);
            return {};
        }
    };

    template <class Ret, class...Args, class RetConvArg, class...ConvArgs>
    std::enable_if_t<(sizeof...(ConvArgs) == sizeof...(Args)), XSCallbackDispatcher*>
    fill_default_args (CallbackDispatcher<Ret(Args...)>& d, RetConvArg&& rcarg, ConvArgs&&...cargs) {
        using OptRet = typename CallbackDispatcher<Ret(Args...)>::OptionalRet;
        return new XSCallbackDispatcherImpl<Ret,
            decltype(create_converter_pair<OptRet>(std::forward<RetConvArg>(rcarg))),
            decltype(create_converter_pair<Args>(std::forward<ConvArgs>(cargs)))...
        >(d, std::forward<RetConvArg>(rcarg), std::forward<ConvArgs>(cargs)...);
    }

    template <class Ret, class...Args, class...Rest>
    std::enable_if_t<(sizeof...(Rest) <= sizeof...(Args)), XSCallbackDispatcher*>
    fill_default_args (CallbackDispatcher<Ret(Args...)>& d, Rest&&...rest) {
        return fill_default_args(d, std::forward<Rest>(rest)..., nullptr);
    }

    template <class Ret, class...Args, class...Rest>
    std::enable_if_t<std::is_void<Ret>::value, XSCallbackDispatcher*>
    create_impl (CallbackDispatcher<Ret(Args...)>& d, Rest&&...rest) {
        return fill_default_args(d, nullptr, std::forward<Rest>(rest)...);
    }

    template <class Ret, class...Args, class...Rest>
    std::enable_if_t<!std::is_void<Ret>::value, XSCallbackDispatcher*>
    create_impl (CallbackDispatcher<Ret(Args...)>& d, Rest&&...rest) {
        return fill_default_args(d, std::forward<Rest>(rest)...);
    }

    template <class Ret, class...Args, class...Rest>
    XSCallbackDispatcher* XSCallbackDispatcher::create (CallbackDispatcher<Ret(Args...)>& d, Rest&&...rest) {
        return create_impl(d, std::forward<decltype(rest)>(rest)...);
    }
}}

namespace xs {
    using XSCallbackDispatcher = callback_dispatcher::XSCallbackDispatcher;

    template <> struct Typemap<XSCallbackDispatcher*> : TypemapObject<XSCallbackDispatcher*, XSCallbackDispatcher*, ObjectTypePtr, ObjectStorageMG> {
       static std::string package () { return "XS::Framework::CallbackDispatcher"; }
    };

    template <typename Ret, class...Args> struct Typemap<panda::CallbackDispatcher<Ret(Args...)>*> {
        static Sv out (pTHX_ panda::CallbackDispatcher<Ret(Args...)>* d, const Sv& = {}) {
            return xs::out(XSCallbackDispatcher::create(*d));
        }
    };
}
