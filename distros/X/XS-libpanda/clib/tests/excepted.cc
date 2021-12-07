#include "test.h"
#include <panda/excepted.h>

TEST_PREFIX("excepted: ", "[excepted]");

TEST("moveable") {
    excepted<int, double> a;
    excepted<int, double> b(std::move(a));
}
