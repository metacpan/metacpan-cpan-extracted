#include "test.h"
#include <panda/error.h>

#define TEST(name) TEST_CASE("error: " name, "[error]")

using namespace panda;

enum MyErr {
    Err1 = 1,
    Err2
};

struct MyCategory : std::error_category {
    const char * name() const noexcept override {return "MyCategory";}
    std::string message(int ev) const override {return std::string("MyErr") + std::to_string(ev);}
};

static const MyCategory my_category;

namespace std {
    template <> struct is_error_code_enum<MyErr> : std::true_type {};
}

std::error_code make_error_code (MyErr err) noexcept { return std::error_code(err, my_category); }

TEST("ErrorCode ctor") {
    SECTION("default") {
        ErrorCode code;
        CHECK_FALSE(code);
        CHECK_FALSE(code.next());
        CHECK_FALSE(code.code());
        CHECK_FALSE(code.next().code());
    }
    SECTION("val+cat") {
        ErrorCode code(2, my_category);
        CHECK(code);
        CHECK_FALSE(code.next());
    }
    SECTION("enum") {
        ErrorCode code(Err1);
        CHECK(code);
        CHECK_FALSE(code.next());
    }
    SECTION("nested") {
        ErrorCode nested_code(Err1);
        ErrorCode code(Err2, nested_code);
        CHECK(code);
        REQUIRE(code.next());
        CHECK_FALSE(code.next().next());
        CHECK(code.what() == "MyErr2 (2:MyCategory) -> MyErr1 (1:MyCategory)");
        nested_code.clear();
        CHECK(code.next() == Err1); // check it was copy and no sharing
    }
}

TEST("ErrorCode methods") {
    ErrorCode e1(Err1);
    ErrorCode e2;
    e2 = e1;
    REQUIRE(e2 == e1);
}

TEST("ErrorCode defctor") {
    ErrorCode orig;
    ErrorCode wrap(Err1, orig);
    CHECK(wrap == Err1);
    CHECK(wrap.next().code().value() == 0);
}

TEST("comparisons") {
    SECTION("ErrorCode to ErrorCode") {
        CHECK(ErrorCode() == ErrorCode());
        CHECK(ErrorCode(MyErr::Err1) == ErrorCode(MyErr::Err1));
        CHECK(ErrorCode(MyErr::Err1) != ErrorCode());
        (void)(ErrorCode() < ErrorCode());
    }
    SECTION("ErrorCode to error_code") {
        CHECK(ErrorCode() == std::error_code());
        CHECK(std::error_code() == ErrorCode());
        CHECK(ErrorCode(MyErr::Err1) != std::error_code());
        CHECK(std::error_code() != ErrorCode(MyErr::Err1));
        (void)(ErrorCode() < std::error_code());
        (void)(std::error_code() < ErrorCode());
    }
    SECTION("ErrorCode to error code enum") {
        CHECK(ErrorCode(MyErr::Err1) == MyErr::Err1);
        CHECK(MyErr::Err1 == ErrorCode(MyErr::Err1));
        CHECK(ErrorCode(MyErr::Err1) != MyErr::Err2);
        CHECK(MyErr::Err1 != ErrorCode(MyErr::Err2));
        (void)(ErrorCode() < MyErr::Err1);
        (void)(MyErr::Err1 < ErrorCode());
    }
    SECTION("ErrorCode to error cond enum") {
        CHECK(ErrorCode(make_error_code(std::errc::operation_canceled)) == std::errc::operation_canceled);
        CHECK(std::errc::operation_canceled == ErrorCode(make_error_code(std::errc::operation_canceled)));
        CHECK(ErrorCode() != std::errc::operation_canceled);
        CHECK(std::errc::operation_canceled != ErrorCode());
        (void)(ErrorCode() < std::errc::operation_canceled);
        (void)(std::errc::operation_canceled < ErrorCode());
    }
}

TEST("bad_expected_access") {
    string what;
    try {
        expected<int, ErrorCode> exp = make_unexpected(ErrorCode(MyErr::Err1));
        exp.value();
    } catch (bad_expected_access<ErrorCode>& e) {
        what = e.what();
    }
    REQUIRE(what == "Bad expected access: MyErr1 (1:MyCategory)");
}

TEST("contains") {
    REQUIRE_FALSE(ErrorCode().contains(make_error_code(MyErr::Err1)));
    REQUIRE_FALSE(ErrorCode(MyErr::Err1).contains({make_error_code(MyErr::Err2)}));

    REQUIRE(ErrorCode().contains({}));
    REQUIRE(ErrorCode(MyErr::Err1).contains({make_error_code(MyErr::Err1)}));

    ErrorCode nested_code(Err1);
    ErrorCode code(Err2, nested_code);
    REQUIRE(code.contains(MyErr::Err1));
    REQUIRE(code.contains(MyErr::Err2));

    ErrorCode triple(make_error_code(std::errc::operation_canceled), code);
    REQUIRE(triple.contains(MyErr::Err1));
    REQUIRE(triple.contains(MyErr::Err2));
    REQUIRE(triple.contains(make_error_code(std::errc::operation_canceled)));
    REQUIRE_FALSE(triple.contains(make_error_code(std::errc::broken_pipe)));
}
