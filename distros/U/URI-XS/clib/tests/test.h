#pragma once
#define CATCH_CONFIG_EXTERNAL_INTERFACES
#include <catch2/catch.hpp>
#include <panda/uri/all.h>

using namespace panda;
using namespace panda::uri;

#define CHECK_TYPE(var, type) CHECK( string_view(typeid(*var).name()) == string_view(typeid(type).name()) )
