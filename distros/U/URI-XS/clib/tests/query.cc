#include "test.h"
#include <regex>

#define TEST(name) TEST_CASE("query: " name, "[query]")

#define CHECKQSTR(uri, re) CHECK(std::regex_search(uri.query_string().c_str(), std::regex("(^|&)" re "(&|$)")));

using vs = std::vector<string>;

template <class T>
static vs getvs (T&& range) {
    vs ret;
    for (auto it = range.first; it != range.second; ++it) ret.push_back(it->second);
    return ret;
}

TEST("query hash") {
    URI uri("https://ya.ru/my/path?p1=v1&p2=v2&p3=a%20b&p2=v2v2&=empty&empty=&#myhash");
    CHECK(uri.query() == Query({
        {"p1", "v1"},
        {"p2", "v2"},
        {"p3", "a b"},
        {"p2", "v2v2"},
        {"", "empty"},
        {"empty", ""},
        {"", ""}
    }));
}

TEST("query hash set") {
    URI uri("https://ya.ru?p1=v1&empty=");
    uri.query({{"a", "1"}, {"key space", "2"}, {"b", "val space"}, {"multi", "1"}, {"multi", "2"}, {"multi", "3"}, {"", "empty"}});

    auto qstr = uri.query_string();
    CHECK(qstr);
    CHECKQSTR(uri, "a=1");
    CHECKQSTR(uri, "key%20space=2");
    CHECKQSTR(uri, "b=val%20space");
    CHECKQSTR(uri, "multi=1");
    CHECKQSTR(uri, "multi=2");
    CHECKQSTR(uri, "multi=3");
    CHECKQSTR(uri, "=empty");
}

TEST("param") {
    URI uri("https://ya.ru/my/path?p1=v1&p2=v2&p3=a%20b&p2=v2v2&=empty&empty=&#myhash");
    CHECK(uri.query().size() == 7);
    CHECK(uri.param("p1") == "v1");
    CHECK(uri.param("p3") == "a b");

    CHECK(uri.has_param(""));
    CHECK(uri.param("empty") == "");

    CHECK(!uri.has_param("nonexistent"));

    CHECK(uri.param("p2") == "v2");
}

TEST("set param") {
    URI uri("https://ya.ru/?p1=v1&p2=v2&p2=v2v2");

    uri.param("p1", "hi");
    CHECK(getvs(uri.multiparam("p1")) == vs{"hi"});

    uri.param("p2", "hello");
    CHECK(getvs(uri.multiparam("p2")) == vs{"hello"});

    uri.param("p3", "world");
    CHECK(getvs(uri.multiparam("p3")) == vs{"world"});
}

TEST("remove param") {
    URI uri("https://ya.ru/?p1=v1&p2=v2&p2=v2v2");
    uri.remove_param("nonexistent");
    CHECK(uri.query() == Query({{"p1", "v1"}, {"p2", "v2"}, {"p2", "v2v2"}}));
    uri.remove_param("p2");
    CHECK(uri.query() == Query({{"p1", "v1"}}));
    uri.remove_param("p1");
    CHECK(uri.query() == Query());
}

TEST("multiparam") {
    URI uri("https://ya.ru/my/path?p1=v1&p2=v2&p3=a%20b&p2=v2v2&=empty&empty=&#myhash");
    CHECK(getvs(uri.multiparam("p1")) == vs{"v1"});
    CHECK(getvs(uri.multiparam("")) == vs{"empty", ""});
    CHECK(getvs(uri.multiparam("p2")) == vs{"v2", "v2v2"});
}

TEST("set multiparam") {
    URI uri("https://ya.ru/?p1=v1&p2=v2&p2=v2v2");

    uri.multiparam("p1", {"1", "2"});
    CHECK(getvs(uri.multiparam("p1")) == vs{"1", "2"});

    uri.multiparam("p2", {"a"});
    CHECK(getvs(uri.multiparam("p2")) == vs{"a"});

    uri.multiparam("p1", {});
    CHECK(!uri.has_param("p1"));

    uri.multiparam("p3", {"a", "b", "c"});
    CHECK(getvs(uri.multiparam("p3")) == vs{"a", "b", "c"});
}

TEST("query string") {
    URI uri("https://ya.ru/?p1=v1&p2=v2&p2=v2%20v2");
    CHECK(uri.query_string() == "p1=v1&p2=v2&p2=v2%20v2");
    uri.multiparam("p1", {});
    CHECK(uri.query_string() == "p2=v2&p2=v2%20v2");
}

TEST("set query string") {
    URI uri("https://ya.ru/?p1=v1&p2=v2&p2=v2%20v2");
    uri.query_string("a=1&b=2");
    CHECK(uri.query() == Query({{"a", "1"}, {"b", "2"}}));
}

TEST("add query string") {
    URI uri("https://ya.ru/my/path?a=b");
    uri.add_query("");
    CHECK(uri.to_string() == "https://ya.ru/my/path?a=b");

    uri.add_query("a=2");
    CHECK(uri.query() == Query({{"a", "b"}, {"a", "2"}}));

    uri.add_query("c=d&e=f%20e");
    CHECK(uri.query() == Query({{"a", "b"}, {"a", "2"}, {"c", "d"}, {"e", "f e"}}));
}

TEST("add query hash") {
    URI uri("https://ya.ru/my/path?a=b&e=f");
    uri.add_query({{"c", "d"}, {"e", "f e"}});
    CHECK(uri.query() == Query({{"a", "b"}, {"c", "d"}, {"e", "f"}, {"e", "f e"}}));
}

TEST("query in ctor is added") {
    URI uri("https://ya.ru/my/path?a=b&c=d", {{"c", "d e"}, {"e", "f"}});
    CHECK(uri.query().size() == 4);
    CHECK(uri.query() == Query({{"a", "b"}, {"c", "d"}, {"c", "d e"}, {"e", "f"}}));
    CHECKQSTR(uri, "a=b");
    CHECKQSTR(uri, "c=d");
    CHECKQSTR(uri, "c=d%20e");
    CHECKQSTR(uri, "e=f");
}

TEST("QUERY_PARAM_SEMICOLON") {
    URI uri("https://ya.ru/my/path?a=b;e=f;c=d%20e", URI::Flags::query_param_semicolon);
    CHECK(uri.query() == Query({{"a", "b"}, {"c", "d e"}, {"e", "f"}}));
    CHECK(std::regex_search(uri.query_string().c_str(), std::regex("[^;]+;[^;]+;[^;]+")));
}

TEST("bug test (no sync query for param())") {
    URI uri("https://graph.facebook.com/v2.2?fields=id%2Cfirst_name%2Clast_name%2Cname%2Cgender%2Cbirthday%2Clink&ids=me&include_headers=false");
    uri.query_string("");
    uri.param("batch", "123");
    CHECK(uri.to_string() == "https://graph.facebook.com/v2.2?batch=123");

}
