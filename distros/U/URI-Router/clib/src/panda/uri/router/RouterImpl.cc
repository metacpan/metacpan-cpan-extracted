#include "RouterImpl.h"
#include <algorithm>

namespace panda { namespace uri { namespace router {

static const string_view method_names[] = {"OPTIONS/", "GET/", "HEAD/", "POST/", "PUT/", "DELETE/", "TRACE/", "CONNECT/"};

static inline string key_from_sv (const string_view& key) {
    using FakeCharLiteral = char[1];
    string tmp(*(const FakeCharLiteral*)key.data());
    tmp.length(key.length());
    return tmp;
}

static inline uint64_t value_for_method (const uint64_t* methods, Method method) {
    auto val = methods[(size_t)method];
    return val == std::numeric_limits<uint64_t>::max() ? methods[(size_t)Method::Unspecified] : val;
}

void RouterImpl::add(string path, bool regex, Method method, uint64_t value) {
    compiled = false;

    if (path && path[0] != '/') {
        for (size_t i = 0; i < sizeof(method_names) / sizeof(string_view); ++i) {
            if (path.find(method_names[i]) != 0) continue;
            method = (Method)(i+1);
            path.offset(method_names[i].length()-1);
            break;
        }
    }

    string re;
    uint64_t penalty = 0;
    bool dynamic = false;
    bool trailing = false;
    string static_invariant;

    if (regex) {
        re = path;
        penalty = std::numeric_limits<uint64_t>::max();
        dynamic = true;
    } else {
        std::vector<string_view> segments;
        size_t plen = path.length();
        if (plen) {
            const char* p = path.data();
            size_t start = 0;
            for (size_t i = 0; i < plen; ++i) {
                if (p[i] != '/') continue;
                if (i == start) { start++; continue; }
                segments.emplace_back(p+start, i-start);
                start = i+1;
            }
            if (p[plen-1] != '/') segments.emplace_back(p+start, plen-start);
        }

        for (size_t i = 0; i < segments.size(); ++i) {
            auto v = segments[i];
            if (v == "*") {
                re += "/([^/]+)";
                penalty += std::numeric_limits<uint64_t>::max() >> (i*2 + 1);
                dynamic = true;
            } else if (v == "..." && i == segments.size() - 1) {
                if (!dynamic) static_invariant = re;
                re += "((?:/[^/]+)*)";
                penalty += std::numeric_limits<uint64_t>::max() >> (i*2);
                dynamic = trailing = true;
            } else {
                re += '/';
                re += v;
            }
        }
    }

    Route* route = nullptr;
    auto it = route_map.find(re);
    if (it != route_map.end()) {
        route = &routes[it->second];
    } else {
        routes.push_back({re, static_invariant, {}, penalty, dynamic, trailing});
        route_map.emplace(re, routes.size()-1);
        route = &routes.back();
        for (size_t i = 0; i < 9; ++i) route->methods[i] = std::numeric_limits<uint64_t>::max();
    }

    route->methods[(size_t)method] = value;
}

void RouterImpl::compile () {
    sorted_routes.clear();
    static_routes.clear();

    std::transform(routes.begin(), routes.end(), std::back_inserter(sorted_routes), [](Route& route) { return &route; });
    std::stable_sort(sorted_routes.begin(), sorted_routes.end(), [](const Route* a, const Route* b) -> bool { return a->penalty < b->penalty; });

    std::vector<string> paths;
    paths.reserve(sorted_routes.size());
    for (auto route : sorted_routes) {
        paths.push_back(route->path);
        if (!route->dynamic){
            static_routes[route->path] = route;
        }
        if (route->static_invariant && static_routes.find(route->static_invariant) == static_routes.end()) {
            static_routes[route->static_invariant] = route;
        }
    }

    dfa.compile(paths);

    compiled = true;
}

optional<RouterImpl::Result> RouterImpl::route (string_view path, Method method) {
    if (!compiled) compile();
    if (!routes.size()) return {};
    //printf("pattern-route: %s\n", string(path).c_str());

    while (path.length() && path.back() == '/') path.remove_suffix(1);

    auto it = static_routes.find(key_from_sv(path));
    if (it != static_routes.end()) {
        auto value = value_for_method(it->second->methods, method);
        if (value == std::numeric_limits<uint64_t>::max()) return {};
        return Result{value, {}};
    }

    auto res = dfa.find(path);
    if (!res) return {};

    auto route = sorted_routes[res->nmatch];
    auto value = value_for_method(route->methods, method);
    if (value == std::numeric_limits<uint64_t>::max()) return {};

    if (route->trailing && res->captures.size()) {
        auto s = res->captures.back();
        bool initial = true;
        size_t pos = 0, newpos;
        while ((newpos = s.find('/', pos)) != string::npos) {
            if (newpos > pos) {
                if (initial) {
                    res->captures.back() = string_view(s.data()+pos, newpos-pos);
                    initial = false;
                }
                else res->captures.emplace_back(s.data()+pos, newpos-pos);
            }
            pos = newpos + 1;
        }
        if (pos < s.length()) {
            if (initial) res->captures.back() = string_view(s.data()+pos, s.length()-pos);
            else res->captures.emplace_back(s.data()+pos, s.length()-pos);
        }
    }

    return Result{value, std::move(res->captures)};
}

}}}
