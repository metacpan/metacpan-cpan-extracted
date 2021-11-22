#pragma once
#include "Dfa.h"
#include <map>
#include <panda/string.h>
#include <panda/optional.h>
#include <ska/flat_hash_map.hpp>

namespace panda { namespace uri { namespace router {

enum class Method { Unspecified = 0, Options, Get, Head, Post, Put, Delete, Trace, Connect };

struct MethodEntry {
    Method   method;
    uint64_t value;
};
using Methods = std::vector<MethodEntry>;

struct RouterImpl {
protected:
    struct Result {
        uint64_t value;
        Captures captures;
    };

    RouterImpl() {}

    void add(string path, bool regex, Method method, uint64_t value);

    optional<Result> route(string_view path, Method method);

private:
    struct Route {
        string   path;
        string   static_invariant;
        uint64_t methods[9];
        uint64_t penalty;
        bool     dynamic;
        bool     trailing;
    };

    struct RuntimeRoute {
        uint64_t methods[9];
    };

    using Routes        = std::vector<Route>;
    using RoutesPtr     = std::vector<Route*>;
    using RouteMap      = ska::flat_hash_map<string, size_t>;
    using StaticRoutes  = ska::flat_hash_map<string, Route*>;
    using RuntimeRoutes = std::vector<RuntimeRoute>;

    bool compiled = false;

    // config
    Routes   routes;
    RouteMap route_map;

    // runtime
    RoutesPtr     sorted_routes;
    StaticRoutes  static_routes;
    Dfa           dfa;

    void compile();
};

}}}
