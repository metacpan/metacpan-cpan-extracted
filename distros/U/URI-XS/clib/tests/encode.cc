#include "test.h"

#define TEST(name) TEST_CASE("encode: " name, "[encode]")

TEST("encode") {
    CHECK(encode_uri_component("hello world") == "hello%20world");
    CHECK(encode_uri_component("http://ya.ru") == "http%3A%2F%2Fya.ru");
    CHECK(encode_uri_component("hello guy! how ru? пиздец нах") == "hello%20guy%21%20how%20ru%3F%20%D0%BF%D0%B8%D0%B7%D0%B4%D0%B5%D1%86%20%D0%BD%D0%B0%D1%85");
    CHECK(encode_uri_component("hello world", URIComponent::query_param_plus) == "hello+world");
}

TEST("decode") {
    CHECK(decode_uri_component("hello%20world") == "hello world");
    CHECK(decode_uri_component("hello+world") == "hello world");
    CHECK(decode_uri_component("http%3A%2F%2Fya.ru") == "http://ya.ru");
    CHECK(decode_uri_component("hello%20guy%21%20how%20ru%3F%20%D0%BF%D0%B8%D0%B7%D0%B4%D0%B5%D1%86%20%D0%BD%D0%B0%D1%85") == "hello guy! how ru? пиздец нах");
}
