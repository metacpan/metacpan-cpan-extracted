#pragma once
#include <initializer_list>
#include "router/RouterImpl.h"

namespace panda { namespace uri {

struct Regex {
    string str;
    Regex() {}
    Regex(const string& re) : str(re) {}
    explicit constexpr operator bool () const { return str.length(); }
};

template <class T>
struct Router : private router::RouterImpl {
    using Method   = router::Method;
    using Captures = router::Captures;

    struct Action {
        string path;
        bool   regex;
        Method method;
        T      value;

        template <class TT>
        Action(const TT& path, const T& value) : Action(Method::Unspecified, path, value) {}
        Action(Method method, const string& path, const T& value) : path(path), regex(false), method(method), value(value) {}
        Action(Method method, const Regex&  re,   const T& value) : path(re.str), regex(true), method(method), value(value) {}
    };

    struct Result {
        T&       value;
        Captures captures;
    };

    Router(std::initializer_list<Action> actions = {}) {
        for (auto& action : actions) add(action);
    }

    void add(const Action& action) {
        vmap.push_back(action.value);
        auto value = vmap.size() - 1;
        RouterImpl::add(action.path, action.regex, action.method, value);
    }

    optional<Result> route(string_view path, Method method = Method::Get) {
        auto opt = RouterImpl::route(path, method);
        if (!opt) return {};
        auto& eres = *opt;
        assert(vmap.size() >= eres.value + 1);
        return Result{vmap[eres.value], std::move(eres.captures)};
    }

private:
    using ValueMap = std::vector<T>;

    ValueMap vmap;
};

}}
