#pragma once
#include "../pp.h"
#include <catch2/catch_test_macros.hpp>

#define TEST_PREFIX(prefix, tag)                                    \
    static inline std::string _test_prefix () { return prefix; }    \
    static inline std::string _test_tag    () { return tag; }

template <class...Args> static inline std::string _test_prefix (Args...) { return {}; }
template <class...Args> static inline std::string _test_tag    (Args...) { return {}; }

#define TEST(...)             PANDA_PP_VFUNC(TEST_IMPL, __VA_ARGS__)
#define TEST_IMPL1(name)      TEST_CASE(_test_prefix() + name, _test_tag())
#define TEST_IMPL2(name, tag) TEST_CASE(_test_prefix() + name, _test_tag() + tag)

#define TEST_MYTAG(name, tag) TEST_CASE(_test_prefix() + name, tag)
#define TEST_HIDDEN(name)     TEST_MYTAG(name, "[.]")
