#pragma once
#include <panda/test/catch.h>
#include <panda/uri/Router.h>

using namespace panda;
using namespace panda::uri;
using panda::uri::router::Method;
using panda::uri::router::Captures;

#define CHECK_ROUTE(path, val) do {                 \
    if (val == -1) CHECK_FALSE(r.route(path));      \
    else {                                          \
        REQUIRE(r.route(path));                     \
        CHECK(r.route(path).value().value == val);  \
    }                                               \
} while (0)
