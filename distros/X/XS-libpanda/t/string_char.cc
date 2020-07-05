#include "string_test.h"
TEST_CASE("basic_string<char>", "[string][string_char]") { test::test_string<char>::run(); }

void test_compilation_warnings () {
    {
        struct {
            uint64_t a;
            uint64_t b;
        } abc;
        auto data = string("\x05\x01\x00\x01") + string((char*)&abc, 16) + string((char*)&abc, 2);
    }

    {
        string str = "andedf";
        string str2 = std::move(str);
    }
}
