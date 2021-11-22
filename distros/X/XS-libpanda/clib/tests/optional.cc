#include "test.h"
#include <panda/optional.h>

TEST_CASE("optional", "[optional]") {
    optional<int> def;
    CHECK_FALSE(def);

    optional<int> ini = 1;
    CHECK(ini);
    CHECK(ini.value() == 1);

    auto x2 = [](int v) { return double(v*2);};

    CHECK(def.and_then(x2) == 0);
    CHECK(ini.and_then(x2) == 2);

    optional<double> od = def.transform(x2);
    CHECK_FALSE(od);
    optional<double> oi = ini.transform(x2);
    CHECK(oi);
    CHECK(oi == 2);

    CHECK(def.or_else([]{return 4;}) == 4);
    CHECK(ini.or_else([]{return 4;}) == 1);
}
