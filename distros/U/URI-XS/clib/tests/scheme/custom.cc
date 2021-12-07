#include "../test.h"
#include <catch2/reporters/catch_reporter_registrars.hpp>
#include <catch2/reporters/catch_reporter_event_listener.hpp>

#define TEST(name) TEST_CASE("scheme-custom: " name, "[scheme-custom]")

struct MyScheme2 : URI::Strict<MyScheme2> {
    using URI::Strict<MyScheme2>::Strict;
    static string default_scheme () { return "myscheme2"; }
};

struct RegisterSchems : Catch::EventListenerBase {
    using EventListenerBase::EventListenerBase; // inherit constructor

    void testRunStarting( Catch::TestRunInfo const&) override {
        URI::register_scheme("myscheme1", 6666, true);
        URI::register_scheme("myscheme2", &typeid(MyScheme2), [](const URI& u)->URI*{ return new MyScheme2(u);  }, 7777, false);
    }
};
CATCH_REGISTER_LISTENER(RegisterSchems);

TEST("simple scheme") {
    auto uri = URI::create("myscheme1://ya.ru");
    CHECK_TYPE(uri, URI);
    CHECK(uri->port() == 6666);
    CHECK(uri->secure());

    uri = new URI("myscheme1://ya.ru");
    CHECK(uri->port() == 6666);
    CHECK(uri->secure());
}

TEST("full scheme") {
    auto uri = URI::create("myscheme2://ya.ru");
    CHECK_TYPE(uri, MyScheme2);
    CHECK(uri->port() == 7777);

    uri = new URI("myscheme2://ya.ru");
    CHECK(uri->port() == 7777);
}
