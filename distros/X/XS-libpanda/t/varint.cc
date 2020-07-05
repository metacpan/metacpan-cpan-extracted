#include "test.h"
#include <panda/varint.h>

#define TEST(name) TEST_CASE("varint: " name, "[varint]")

TEST("encode") {
    CHECK(varint_encode(0) == string("\0"));
    CHECK(varint_encode(1) == string("\1"));
    CHECK(varint_encode(127) == string("\x7f"));

    CHECK(varint_encode(128) == string("\x80\1"));
    CHECK(varint_encode(129) == string("\x81\1"));
}

TEST("decode") {
    string start = GENERATE(string(""), string("\0"), string("\x80"));
    CHECK(varint_decode(start + string("\0"), start.length()) == 0);
    CHECK(varint_decode(start + string("\1"), start.length()) == 1);
    CHECK(varint_decode(start + string("\x7f"), start.length()) == 127);

    CHECK(varint_decode(start + string("\x80\1"), start.length()) == 128);
    CHECK(varint_decode(start + string("\x81\1"), start.length()) == 129);
}

TEST("cross check") {
    for (uint32_t i = 0; i < 256; ++i) {
        if (varint_decode(varint_encode(i)) != i) {
            FAIL(i);
        }
    }
    for (uint32_t i = 0; i < 500000; i+=29) {
        if (varint_decode(varint_encode(i)) != i) {
            FAIL(i);
        }
    }
    REQUIRE(true);
}

TEST("varint_s cross check") {
    for (int i = 256; i < 256; ++i) {
        if (varint_decode_s(varint_encode_s(i)) != i) {
            FAIL(i);
        }
    }
    for (int i = -500000; i < 500000; i+=29) {
        int res = varint_decode_s(varint_encode_s(i));
        if (res != i) {
            INFO(res);
            FAIL(i);
        }
    }
    REQUIRE(true);
}

TEST("VarIntStack") {
    VarIntStack stack;
    stack.push(300);
    stack.push(400);
    CHECK(stack.top() == 400);
    stack.pop();
    CHECK(stack.top() == 300);
}

TEST("VarIntStack iterator") {
    VarIntStack stack;
    SECTION("empty") {
        REQUIRE(stack.begin() == stack.end());
    }
    SECTION("simple") {
        using vec = std::vector<int>;
        vec src = GENERATE(vec{0}, vec{1}, vec{0,1}, vec{1,128,0,100000, 0xFFFFFF});
        for (int v : src) {
            stack.push(v);
        }
        vec res;
        std::copy(stack.begin(), stack.end(), std::back_inserter(res));
        std::reverse(res.begin(), res.end()); // Stack reverses order
        REQUIRE(src == res);
    }
}
