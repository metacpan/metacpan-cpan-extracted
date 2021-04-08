#include "test.h"

#define TEST(name) TEST_CASE("change: " name, "[change]")

TEST("scheme") {
    URI uri("http://ya.ru");

    uri.scheme("https");
    CHECK(uri.scheme() == "https");
    CHECK(uri.to_string() ==  "https://ya.ru");

    uri.scheme("");
    CHECK(uri.scheme() == "");
    CHECK(uri.to_string() ==  "//ya.ru");
}

TEST("host") {
    URI uri("http://norm.com/");

    uri.host("jopa.com");
    CHECK(uri.host() == "jopa.com");
    CHECK(uri.to_string() ==  "http://jopa.com/");
}

TEST("port") {
    URI uri("https://ya.ru/");

    uri.port(1000);
    CHECK(uri.explicit_port() == 1000);
    CHECK(uri.port() == 1000);
    CHECK(uri.to_string() == "https://ya.ru:1000/");

    uri.port(0);
    CHECK(uri.explicit_port() ==  0);
    CHECK(uri.port() == 443);
    CHECK(uri.to_string() == "https://ya.ru/");
}

TEST("path") {
    URI uri("http://ya.ru/o/l/d/path?a=b");

    uri.path("/new/path/nah/");
    CHECK(uri.path() == "/new/path/nah/");
    CHECK(uri.to_string() == "http://ya.ru/new/path/nah/?a=b");

    uri.path("");
    CHECK(uri.path() == "");
    CHECK(uri.to_string() == "http://ya.ru?a=b");
}

TEST("query string") {
    URI uri("http://ya.ru?a=b#myhash");

    uri.query_string("mama=papa&jopa=popa");
    CHECK(uri.query_string() == "mama=papa&jopa=popa");
    CHECK(uri.to_string() == "http://ya.ru?mama=papa&jopa=popa#myhash");

    uri.query_string("");
    CHECK(uri.query_string() == "");
    CHECK(uri.to_string() == "http://ya.ru#myhash");
}

TEST("fragment") {
    URI uri("https://ya.ru#hash");

    uri.fragment("suka-sosi-her");
    CHECK(uri.fragment() == "suka-sosi-her");
    CHECK(uri.to_string() ==  "https://ya.ru#suka-sosi-her");

    uri.fragment("");
    CHECK(uri.fragment() == "");
    CHECK(uri.to_string() == "https://ya.ru");
}

TEST("location") {
    URI uri("http://ya.ru/");

    uri.location("mail.ru:8000");
    CHECK(uri.to_string() == "http://mail.ru:8000/");
    CHECK(uri.host() == "mail.ru");
    CHECK(uri.explicit_port() == 8000);
    CHECK(uri.location() == "mail.ru:8000");

    uri.location("vk.com:");
    CHECK(uri.to_string() == "http://vk.com/");
    CHECK(uri.explicit_port() == 0);
    CHECK(uri.port() == 80);
}
