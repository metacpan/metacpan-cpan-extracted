#include "../test.h"

static void test (const URISP& uri, uint16_t port, bool secure, string friend_scheme = "") {
    SECTION(std::string(uri->scheme().c_str())) {
        char sign = friend_scheme ? friend_scheme[0] : 0;
        friend_scheme.erase(0, 1);

        auto autouri = URI::create(uri->to_string());

        CHECK(typeid(*uri).hash_code() == typeid(*autouri).hash_code() );
        CHECK(uri->port() == port);
        CHECK(uri->secure() == secure);

        if (friend_scheme) {
            if (sign == '+') {
                uri->scheme(friend_scheme);
                CHECK(uri->scheme() == friend_scheme);
            } else {
                CHECK_THROWS_AS(uri->scheme(friend_scheme), WrongScheme);
            }
        }
    }
}

TEST_CASE("scheme-list", "[scheme-list]") {
    test(new URI::http  ("http://ya.ru"),     80, false, "+https");
    test(new URI::https ("https://ya.ru"),   443, true,  "-http");
    test(new URI::ws    ("ws://ya.ru"),       80, false, "+wss");
    test(new URI::wss   ("wss://ya.ru"),     443, true,  "-ws");
    test(new URI::ftp   ("ftp://ya.ru"),      21, false);
    test(new URI::sftp  ("sftp://server"),    22, true);
    test(new URI::socks ("socks5://ya.ru"), 1080, false);
    test(new URI::ssh   ("ssh://server"),     22, true);
    test(new URI::telnet("telnet://server"),  23, false);
}
