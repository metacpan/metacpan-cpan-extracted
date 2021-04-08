#include "test.h"

#define TEST(name) TEST_CASE("parse-stringify: " name, "[parse-stringify]")

static int flags;

URI test (string url, string scheme, string uinfo, string host, uint16_t port = 0, string path = "", string qstr = "", string fragment = "", string checkstr = "") {
    string testname = "test url " + url;
    if (flags) testname += " (flags=" + panda::to_string(flags) + ")";
    if (!checkstr) checkstr = url;

    URI uri(url, flags);

    SECTION(testname) {
        CHECK(uri.scheme() == scheme);
        CHECK(uri.user_info() == uinfo);
        CHECK(uri.host() == host);
        CHECK(uri.explicit_port() == port);
        CHECK(uri.path() == path);
        CHECK(uri.query_string() == qstr);
        CHECK(uri.fragment() == fragment);
        CHECK(uri.to_string() == checkstr);
    }

    return uri;
}

void test_wrong (string url) {
    SECTION("test bad url " + url) {
        CHECK(URI(url) == URI());
    }
}

TEST("empty") {
    test("", "", "", "");
}

TEST("scheme") {
    SECTION("scheme -> authority") {
        test("http://host", "http", "", "host");
        test("ws://host", "ws", "", "host");
    }
    SECTION("scheme -> path") {
        test("mailto:syber@crazypanda.ru", "mailto", "", "", 0, "syber@crazypanda.ru");
        test("a:b:c:d:e:f", "a", "", "", 0, "b:c:d:e:f");
        test("cp:/jopa", "cp", "", "", 0, "/jopa");
    }
    SECTION("scheme-relative") {
        test("//ya.ru", "", "", "ya.ru");
    }
}

TEST("user info") {
    test("http://user@ya.ru", "http", "user", "ya.ru");
    test("http://user:pass@ya.ru", "http", "user:pass", "ya.ru");
    test("http://user:@ya.ru", "http", "user:", "ya.ru");
    test_wrong("http://cool@user@ya.ru"); // invalid chars
}

TEST("host") {
    SECTION("reg name") {
        test("http://ya.ru", "http", "", "ya.ru");
    }
    SECTION("IPv4") {
        test("http://1.10.100.255", "http", "", "1.10.100.255");
        test("http://0.0.0.0", "http", "", "0.0.0.0");
    }
    SECTION("IPv6") {
        test("http://[aa:bb:cc:dd::ee:ff]", "http", "", "[aa:bb:cc:dd::ee:ff]");
        test("http://[aa:bb:cc:dd::]", "http", "", "[aa:bb:cc:dd::]");
        test("http://user@[::ee:ff]", "http", "user", "[::ee:ff]");
        test_wrong("http://[aa:bb:cc:dd:ee:ff]"); // wrong address
        test_wrong("http://[aa:bb:cc:dd::ee:ff"); // wrong address
        test_wrong("http://[aa:bb:cc:dd:ee:::ff]"); // wrong address
    }
}

TEST("port") {
    SECTION("explicit") {
        test("http://ya.ru", "http", "", "ya.ru", 0);
        test("abc://ya.ru:80", "abc", "", "ya.ru", 80);
        test("def://ya.ru:443", "def", "", "ya.ru", 443);
    }
    SECTION("implicit") {
        URI uri("http://ya.ru");
        CHECK(uri.port() == 80);
        uri = "http://ya.ru:81";
        CHECK(uri.port() == 81);
        uri = "https://ya.ru";
        CHECK(uri.port() == 443);
        uri = "https://ya.ru:444";
        CHECK(uri.port() == 444);
        uri = "hz://ya.ru";
        CHECK(uri.port() == 0);
    }
}

TEST("location") {
    SECTION("explicit") {
        URI uri("http://ya.ru");
        CHECK(uri.explicit_location() == "ya.ru");
        uri = "http://ya.ru:81";
        CHECK(uri.explicit_location() == "ya.ru:81");
    }
    SECTION("implicit") {
        URI uri("http://ya.ru");
        CHECK(uri.location() == "ya.ru:80");
        uri = "http://ya.ru:81";
        CHECK(uri.location() == "ya.ru:81");
        uri = "https://ya.ru";
        CHECK(uri.location() == "ya.ru:443");
        uri = "https://ya.ru:444";
        CHECK(uri.location() == "ya.ru:444");
        uri = "hz://ya.ru";
        CHECK(uri.location() == "ya.ru:0");
    }
}

TEST("path") {
    SECTION("absolute") {
        test("http://host", "http", "", "host", 0, "");
        test("http://host/", "http", "", "host", 0, "/");
        test("http://host/path", "http", "", "host", 0, "/path");
    }
    SECTION("scheme-relative") {
        test("//host", "", "", "host", 0, "");
        test("//host/", "", "", "host", 0, "/");
        test("//host/path", "", "", "host", 0, "/path");
    }
    SECTION("scheme->path") {
        test("about:", "about", "", "", 0, "");
        test("about:/", "about", "", "", 0, "/");
        test("about:/path", "about", "", "", 0, "/path");
        test("about:path", "about", "", "", 0, "path");
        test("about:path/", "about", "", "", 0, "path/");
    }
    SECTION("relative") {
        test("a", "", "", "", 0, "a");
        test("/", "", "", "", 0, "/");
        test("/abc", "", "", "", 0, "/abc");

        // according to RFC, "ya.ru" is not a host, it's a part of the path
        // to parse "ya.ru" as host (like browsers), we need to enable special mode ALLOW_SUFFIX_REFERENCE
        test("ya.ru/abc", "", "", "", 0, "ya.ru/abc");

        CHECK(URI("http://ya.ru").relative() == "/"); // not empty relative path
        CHECK(URI("http://ya.ru?p1=v1&p2=v2#myhash").relative() == "/?p1=v1&p2=v2#myhash");
    }
}

TEST("query string") {
    test("http://ya.ru?sukastring", "http", "", "ya.ru", 0, "", "sukastring");
    auto uri = test("http://ya.ru?suka%20string+nah", "http", "", "ya.ru", 0, "", "suka%20string+nah");
    CHECK(uri.raw_query() ==  "suka string nah");
}

TEST("fragment") {
    test("http://ya.ru#frag", "http", "", "ya.ru", 0, "", "", "frag");
    test("http://ya.ru#my%23frag", "http", "", "ya.ru", 0, "", "", "my%23frag");
    test("http://ya.ru?p1=v1#myhash", "http", "", "ya.ru", 0, "", "p1=v1", "myhash");
    test("https://jopa.com#a?b?c", "https", "", "jopa.com", 0, "", "", "a?b?c");
    test_wrong("http://ya.ru#my#frag"); // invalid chars in fragment;
}

TEST("leading authority euristics") {
    flags = URI::Flags::allow_suffix_reference;
    test("ya.ru:8080", "", "", "ya.ru", 8080, "", "", "", "//ya.ru:8080");
    test("ya.ru", "", "", "ya.ru", 0, "", "", "", "//ya.ru");
    test("ya.ru:", "ya.ru", "", "", 0);
    test("ya.ru:80a", "ya.ru", "", "", 0, "80a");
    test("ya.ru:8080/a/b", "", "", "ya.ru", 8080, "/a/b", "", "", "//ya.ru:8080/a/b");
    test("ya.ru/a/b", "", "", "ya.ru", 0, "/a/b", "", "", "//ya.ru/a/b");
    test("ya.ru:/a/b", "ya.ru", "", "", 0, "/a/b");
    test("ya.ru:80a/a/b", "ya.ru", "", "", 0, "80a/a/b");
    flags = 0;
}

TEST("allow extended chars") {
    URI uri("http://jopa.com?\"key\"=\"val\"&param={\"key\",\"val\"}", URI::Flags::allow_extended_chars);
    CHECK(uri.query_string() == "%22key%22=%22val%22&param=%7B%22key%22%2C%22val%22%7D");
    CHECK(uri.to_string() == "http://jopa.com?%22key%22=%22val%22&param=%7B%22key%22%2C%22val%22%7D");
    CHECK(uri.query() == Query({{"\"key\"", "\"val\""}, {"param", "{\"key\",\"val\"}"}}));
}

TEST("secure") {
    CHECK(URI("https://ya.ru").secure());
    CHECK(!URI("http://ya.ru").secure());
    CHECK(!URI("//ya.ru").secure());
    CHECK(!URI("ya.ru").secure());
}

TEST("misc") {
    test("mailto:syber@crazypanda.ru?a=b#dada", "mailto", "", "", 0, "syber@crazypanda.ru", "a=b", "dada");
    test("http://user@ya.ru:2345/my/path?p1=v1&p2=v2#myhash", "http", "user", "ya.ru", 2345, "/my/path", "p1=v1&p2=v2", "myhash");
    test("http://user:pass@ya.ru:2345/my/path?p1=v1&p2=v2#myhash", "http", "user:pass", "ya.ru", 2345, "/my/path", "p1=v1&p2=v2", "myhash");
    test("http://user:@ya.ru:2345/my/path?p1=v1&p2=v2#myhash", "http", "user:", "ya.ru", 2345, "/my/path", "p1=v1&p2=v2", "myhash");
    test("http://1.10.100.255:2345/my/path?p1=v1&p2=v2#myhash", "http", "", "1.10.100.255", 2345, "/my/path", "p1=v1&p2=v2", "myhash");
    test("http://hi@1.10.100.255:2345/my/path?p1=v1&p2=v2#myhash", "http", "hi", "1.10.100.255", 2345, "/my/path", "p1=v1&p2=v2", "myhash");
    test("http://[aa:bb:cc:dd::ee:ff]/my/path?p1=v1&p2=v2#myhash", "http", "", "[aa:bb:cc:dd::ee:ff]", 0, "/my/path", "p1=v1&p2=v2", "myhash");
    test("http://[aa:bb:cc:dd::]:2345/my/path?p1=v1&p2=v2#myhash", "http", "", "[aa:bb:cc:dd::]", 2345, "/my/path", "p1=v1&p2=v2", "myhash");
    test("http://user@[::ee:ff]:2345/my/path?p1=v1&p2=v2#myhash", "http", "user", "[::ee:ff]", 2345, "/my/path", "p1=v1&p2=v2", "myhash");
    test("//sss@ya.ru:2345/my/path?p1=v1&p2=v2#myhash", "", "sss", "ya.ru", 2345, "/my/path", "p1=v1&p2=v2", "myhash");
    test("//[aa:bb:cc:dd::ee:ff]/my/path?p1=v1&p2=v2#myhash", "", "", "[aa:bb:cc:dd::ee:ff]", 0, "/my/path", "p1=v1&p2=v2", "myhash");
}

TEST("bad") {
    CHECK(URI("http://api.odnokl\x5C\x00\x03\x06\x00\x00\x00\x00\x00\x00\x00\x23\xC3\xABlq\x1B\x00\x02") == URI()); // null byte in uri. should NOT core dump. Stop parsing url on null byte
    test_wrong("https://jopa.com:123/://asd/?:hello?://yo?u/#lalala://hello/?a=b&jopa=#privet");
}
