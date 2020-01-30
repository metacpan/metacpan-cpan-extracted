#include "test.h"
#include <panda/string.h>
#include <panda/from_chars.h>

using panda::string;

struct Exc : std::exception {};

template <typename T> struct nstr;
template <> struct nstr<int8_t> {
    static string min () { return "-128"; }
    static string max () { return "127"; }
};
template <> struct nstr<uint8_t> {
    static string min () { return "0"; }
    static string max () { return "255"; }
};
template <> struct nstr<int16_t> {
    static string min () { return "-32768"; }
    static string max () { return "32767"; }
};
template <> struct nstr<uint16_t> {
    static string min () { return "0"; }
    static string max () { return "65535"; }
};
template <> struct nstr<int32_t> {
    static string min () { return "-2147483648"; }
    static string max () { return "2147483647"; }
};
template <> struct nstr<uint32_t> {
    static string min () { return "0"; }
    static string max () { return "4294967295"; }
};
template <> struct nstr<int64_t> {
    static string min () { return "-9223372036854775808"; }
    static string max () { return "9223372036854775807"; }
};
template <> struct nstr<uint64_t> {
    static string min () { return "0"; }
    static string max () { return "18446744073709551615"; }
};

template<typename Int>
string tci (Int val, int base = 10, size_t buflen = 100) {
    string s;
    char* buf = s.reserve(buflen);
    char* bufend = buf + buflen;
    auto res = panda::to_chars(buf, bufend, val, base);
    s.length(res.ptr - buf);
    if (res.ec) throw Exc();
    return s;
}

template <typename Int, bool is_signed = std::numeric_limits<Int>::is_signed>
struct test_sign_dependent;

template <typename Int>
struct test_sign_dependent<Int, true> {
    static void run () {
        SECTION("negative number") {
            REQUIRE(tci<Int>(-99) == "-99");
        }

        SECTION("no space") {
            REQUIRE_THROWS_AS(tci<Int>(-123, 10, 3), Exc);
        }

        SECTION("min") {
            REQUIRE(tci<Int>(std::numeric_limits<Int>::min()) == nstr<Int>::min());
        }
    }
};

template <typename Int>
struct test_sign_dependent<Int, false> {
    static void run () {}
};

template <typename Int>
void to_chars_test() {
    SECTION("positive number") {
        REQUIRE(tci<Int>(12) == "12");
    }

    SECTION("zero") {
        REQUIRE(tci<Int>(0) == "0");
    }

    SECTION("max") {
        REQUIRE(tci<Int>(std::numeric_limits<Int>::max()) == nstr<Int>::max());
    }

    SECTION("8-base") {
        REQUIRE(tci<Int>(10, 8) == "12");
    }

    SECTION("16-base") {
        REQUIRE(tci<Int>(10, 16) == "a");
    }

    SECTION("no space") {
        REQUIRE_THROWS_AS(tci<Int>(123, 10, 2), Exc);
    }

    test_sign_dependent<Int>::run();
}

TEST_CASE("to_chars int8_t",   "[to_chars]") { to_chars_test<int8_t>(); }
TEST_CASE("to_chars int16_t",  "[to_chars]") { to_chars_test<int16_t>(); }
TEST_CASE("to_chars int32_t",  "[to_chars]") { to_chars_test<int32_t>(); }
TEST_CASE("to_chars int64_t",  "[to_chars]") { to_chars_test<int64_t>(); }
TEST_CASE("to_chars uint8_t",  "[to_chars]") { to_chars_test<uint8_t>(); }
TEST_CASE("to_chars uint16_t", "[to_chars]") { to_chars_test<uint16_t>(); }
TEST_CASE("to_chars uint32_t", "[to_chars]") { to_chars_test<uint32_t>(); }
TEST_CASE("to_chars uint64_t", "[to_chars]") { to_chars_test<uint64_t>(); }

