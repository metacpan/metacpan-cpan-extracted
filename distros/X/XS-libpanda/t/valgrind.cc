#include "test.h"
#include <panda/string.h>

TEST_CASE("basic_string<char>, valgrind warning on c_str()", "[valgrind]") {
    auto val = external_fn();
    auto str = string(val);
    auto l = strlen(str.c_str());
    CHECK(l > 0);
}

