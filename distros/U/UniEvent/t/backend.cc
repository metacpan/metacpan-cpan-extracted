#include "lib/test.h"
#include <panda/unievent/backend/uv.h>

TEST_CASE("backend", "[backend]") {

    CHECK(backend::UV->name() == "uv");
    REQUIRE(default_backend() == backend::UV);
    REQUIRE_THROWS( set_default_backend(nullptr) );

    // change backend before actions
    set_default_backend(backend::UV);
    REQUIRE(default_backend() == backend::UV);

    LoopSP l = new Loop(backend::UV); // create local loop

    // change backend before global/default loop created
    set_default_backend(backend::UV);
    REQUIRE(default_backend() == backend::UV);

    CHECK(Loop::global_loop());
    CHECK(Loop::default_loop());

    REQUIRE_THROWS(set_default_backend(backend::UV));
}
