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
    {
        string_view in("123zzz");
        in.find("zzz");
    }
}

TEST_CASE("string synopsis", "[string]") {
    using panda::string;
    string a = "hello, ";
    string b("world!!!", 6);
    string c = a + b;
    REQUIRE(c == "hello, world!");

    //CoW, no copy on assignment or substr
    string copy = a;
    REQUIRE(copy.data() == a.data());
    copy[1] = 'a';
    REQUIRE(a == "hello, ");
    REQUIRE(copy == "hallo, ");


    string sub = a.substr(0, 4);
    REQUIRE(sub.data() == a.data());
}
