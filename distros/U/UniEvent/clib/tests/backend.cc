#include "lib/test.h"
#include <panda/unievent/backend/uv.h>

TEST_PREFIX("backend: ", "[backend]");

TEST("default backend is UV") {
    CHECK(backend::UV->name() == "uv");
    REQUIRE(default_backend() == backend::UV);
}

TEST("throws on set nullptr") {
    REQUIRE_THROWS( set_default_backend(nullptr) );
}

TEST("change backend before actions") {
    set_default_backend(backend::UV);
    REQUIRE(default_backend() == backend::UV);
}

TEST("change backend before global/default loop created") {
    LoopSP l = new Loop(backend::UV); // create local loop
    set_default_backend(backend::UV);
    REQUIRE(default_backend() == backend::UV);
}

TEST("throws on change backend after global/default loop is created") {
    CHECK(Loop::global_loop());
    CHECK(Loop::default_loop());
    REQUIRE_THROWS(set_default_backend(backend::UV));
}
