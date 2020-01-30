#include "test.h"
#include <panda/string.h>
#include <panda/from_chars.h>

using panda::string;

struct Exc : std::exception {};

template <typename T> struct nstr;
template <> struct nstr<int8_t> {
    static string min  () { return "-128"; }
    static string max  () { return "127"; }
    static string mmin () { return "-129"; }
    static string mmax () { return "128"; }
};
template <> struct nstr<uint8_t> {
    static string min  () { return "0"; }
    static string max  () { return "255"; }
    static string mmin () { return ""; }
    static string mmax () { return "256"; }
};
template <> struct nstr<int16_t> {
    static string min  () { return "-32768"; }
    static string max  () { return "32767"; }
    static string mmin () { return "-32769"; }
    static string mmax () { return "32768"; }
};
template <> struct nstr<uint16_t> {
    static string min  () { return "0"; }
    static string max  () { return "65535"; }
    static string mmin () { return ""; }
    static string mmax () { return "65536"; }
};
template <> struct nstr<int32_t> {
    static string min  () { return "-2147483648"; }
    static string max  () { return "2147483647"; }
    static string mmin () { return "-2147483649"; }
    static string mmax () { return "2147483648"; }
};
template <> struct nstr<uint32_t> {
    static string min  () { return "0"; }
    static string max  () { return "4294967295"; }
    static string mmin () { return ""; }
    static string mmax () { return "4294967296"; }
};
template <> struct nstr<int64_t> {
    static string min  () { return "-9223372036854775808"; }
    static string max  () { return "9223372036854775807"; }
    static string mmin () { return "-9223372036854775809"; }
    static string mmax () { return "9223372036854775808"; }
};
template <> struct nstr<uint64_t> {
    static string min  () { return "0"; }
    static string max  () { return "18446744073709551615"; }
    static string mmin () { return ""; }
    static string mmax () { return "18446744073709551616"; }
};

template<typename Int>
Int fci (string str, unsigned& pos, int base = 10) {
    Int val;
    auto res = panda::from_chars(str.data() + pos, str.data() + str.size() - pos, val, base);
    pos = res.ptr - str.data();
    if (res.ec) throw Exc();
    return val;
}

template <typename Int, bool is_signed = std::numeric_limits<Int>::is_signed>
struct test_sign_dependent;

template <typename Int>
struct test_sign_dependent<Int, true> {
    static void run () {
        unsigned pos = 0;

        SECTION("negative number") {
            REQUIRE(fci<Int>("-65", pos) == -65);
            REQUIRE(pos == 3);
        }

        SECTION("under min") {
            REQUIRE_THROWS_AS(fci<Int>(nstr<Int>::mmin(), pos), Exc);
            REQUIRE(pos == nstr<Int>::mmin().size());
        }

        SECTION("-dohuya") {
            REQUIRE_THROWS_AS(fci<Int>("    -123456789012345678901234567890123456789012345678901234567890", pos), Exc);
            REQUIRE(pos == 65);
        }

        SECTION("negative 8-base") {
            REQUIRE(fci<Int>(" -0012", pos, 8) == -10);
            REQUIRE(pos == 6);
        }

        SECTION("negative 16-base") {
            REQUIRE(fci<Int>("  -0Dqwe", pos, 16) == -13);
            REQUIRE(pos == 5);
        }
    }
};

template <typename Int>
struct test_sign_dependent<Int, false> {
    static void run () {
        unsigned pos = 0;

        SECTION("negative number") {
            REQUIRE_THROWS_AS(fci<Int>("-65", pos), Exc);
            REQUIRE(pos == 0);
        }
    }
};

template <typename Int>
void from_chars_test() {
    unsigned pos = 0;

    SECTION("just number") {
        REQUIRE(fci<Int>("12", pos) == 12);
        REQUIRE(pos == 2);
    }

    SECTION("+ sign not supported") {
        REQUIRE_THROWS_AS(fci<Int>("+55", pos), Exc);
        REQUIRE(pos == 0);
    }

    SECTION("junk after number") {
        REQUIRE(fci<Int>("14abc", pos) == 14);
        REQUIRE(pos == 2);
    }

    SECTION("spaces before number") {
        REQUIRE(fci<Int>("     32epta", pos) == 32);
        REQUIRE(pos == 7);
    }

    SECTION("floating point") {
        REQUIRE(fci<Int>(" 65.3", pos) == 65);
        REQUIRE(pos == 3);
    }

    SECTION("junk only") {
        REQUIRE_THROWS_AS(fci<Int>("asdff", pos), Exc);
        REQUIRE(pos == 0);
    }

    SECTION("empty") {
        REQUIRE_THROWS_AS(fci<Int>("", pos), Exc);
        REQUIRE(pos == 0);
    }

    SECTION("non-digits only") {
        REQUIRE_THROWS_AS(fci<Int>("  -", pos), Exc);
        REQUIRE(pos == 0);
    }

    SECTION("max") {
        REQUIRE(fci<Int>(nstr<Int>::max(), pos) == std::numeric_limits<Int>::max());
        REQUIRE(pos == nstr<Int>::max().size());
    }

    SECTION("above max") {
        REQUIRE_THROWS_AS(fci<Int>(nstr<Int>::mmax(), pos), Exc);
        REQUIRE(pos == nstr<Int>::mmax().size());
    }

    SECTION("dohuya") {
        REQUIRE_THROWS_AS(fci<Int>("     123456789012345678901234567890123456789012345678901234567890", pos), Exc);
        REQUIRE(pos == 65);
    }

    SECTION("min") {
        REQUIRE(fci<Int>(nstr<Int>::min(), pos) == std::numeric_limits<Int>::min());
        REQUIRE(pos == nstr<Int>::min().size());
    }

    SECTION("8-base") {
        SECTION("simple") {
            REQUIRE(fci<Int>("11", pos, 8) == 9);
            REQUIRE(pos == 2);
        }
        SECTION("with leading zero") {
            REQUIRE(fci<Int>("011", pos, 8) == 9);
            REQUIRE(pos == 3);
        }
    }

    SECTION("16-base") {
        SECTION("simple") {
            REQUIRE(fci<Int>("11", pos, 16) == 17);
            REQUIRE(pos == 2);
        }
        SECTION("0x not supported for 16-base") {
            REQUIRE(fci<Int>("0x10", pos, 16) == 0);
            REQUIRE(pos == 1);
        }
        SECTION("letters") {
            REQUIRE(fci<Int>("0F", pos, 16) == 15);
            REQUIRE(pos == 2);
        }
    }

    SECTION("invalid base") {
        SECTION("0-base = 10 base") {
            REQUIRE(fci<Int>("12", pos, 0) == 12);
            REQUIRE(pos == 2);
        }
        SECTION("1-base = 10 base") {
            REQUIRE(fci<Int>("13", pos, 0) == 13);
            REQUIRE(pos == 2);
        }
        SECTION("36-base") {
            REQUIRE(fci<Int>("13", pos, 36) == 39);
            REQUIRE(pos == 2);
        }
        SECTION(">36-base = 10 base") {
            REQUIRE(fci<Int>("13", pos, 37) == 13);
            REQUIRE(pos == 2);
        }
    }

    test_sign_dependent<Int>::run();
}

TEST_CASE("from_chars int8_t",   "[from_chars]") { from_chars_test<int8_t>(); }
TEST_CASE("from_chars int16_t",  "[from_chars]") { from_chars_test<int16_t>(); }
TEST_CASE("from_chars int32_t",  "[from_chars]") { from_chars_test<int32_t>(); }
TEST_CASE("from_chars int64_t",  "[from_chars]") { from_chars_test<int64_t>(); }
TEST_CASE("from_chars uint8_t",  "[from_chars]") { from_chars_test<uint8_t>(); }
TEST_CASE("from_chars uint16_t", "[from_chars]") { from_chars_test<uint16_t>(); }
TEST_CASE("from_chars uint32_t", "[from_chars]") { from_chars_test<uint32_t>(); }
TEST_CASE("from_chars uint64_t", "[from_chars]") { from_chars_test<uint64_t>(); }

