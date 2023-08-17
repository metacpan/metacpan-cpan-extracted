#include "test.h"
#include <panda/excepted.h>

TEST_PREFIX("excepted: ", "[excepted]");

TEST("moveable") {
    excepted<int, double> a;
    excepted<int, double> b(std::move(a));
}

excepted<void, string> process(const char* c) {
    if (string(c) != "good") {
        return make_unexpected("bad");
    }
    return {};
}

TEST("synopsis") {
    CHECK_THROWS(
        process("bad") // exception thrown, you shoud assign and check the result
    );

    auto ret = process("bad");
    if (!ret) {
        INFO(ret.error());
    } // no problem, ret was checked and processed

    process("good"); // no error, no problem

}