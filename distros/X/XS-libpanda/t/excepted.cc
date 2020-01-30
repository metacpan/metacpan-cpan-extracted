#include "test.h"
#include <panda/excepted.h>

using panda::excepted;

TEST_CASE("excepted", "[excepted]") {
    SECTION("copyable") {
        excepted<int, double> a;
        excepted<int, double> b(a);
    }
}
