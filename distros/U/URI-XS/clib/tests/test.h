#pragma once
#include <panda/uri/all.h>
#include <catch2/catch_test_macros.hpp>

using namespace panda;
using namespace panda::uri;

#define CHECK_TYPE(var, type) CHECK( string_view(typeid(*var).name()) == string_view(typeid(type).name()) )
