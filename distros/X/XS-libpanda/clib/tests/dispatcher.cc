#include "test.h"
#include <panda/function_utils.h>
#include <panda/CallbackDispatcher.h>

using Dispatcher = CallbackDispatcher<int(int)>;
using Event = Dispatcher::Event;

#define TEST(name) TEST_CASE("callback dispatcher: " name, "[callback dispatcher]")

TEST("empty") {
    Dispatcher d;
    d(1);
    REQUIRE(true);
}

TEST("synopsis") {
    CallbackDispatcher<void()> d1;
    string output;
    function<void()> hello = [&]() { output += "Hello,"; };
    function<void()> world = [&]() { output += " World!"; };
    d1.add(hello);
    d1.add(world);
    d1(); // both callback are called in the same order they were added
    assert(output == "Hello, World!");

    d1.remove(world);
    d1(); // only hello remains
    assert(output == "Hello, World!Hello,");

    using IntInt = CallbackDispatcher<int(int)>;
    IntInt d2;
    d2.add_event_listener([](IntInt::Event& event, int val) {
        return event.next(val).value_or(val) * 2; // do what you want with other listeners result
    });
    d2.add_event_listener([](IntInt::Event& /*event*/, int val) {
        return val + 1; // or event skip calling others
    });
    d2.add_event_listener([](IntInt::Event& /*event*/, int /*val*/) -> int {
        throw std::exception(); // never called
    });

    optional<int> result = d2(42); // 2 * (42 + 1) == 86
    assert(result.value() == 86);
}

TEST("dispatcher void()") {
    CallbackDispatcher<void()> d;
    bool called = false;
    CallbackDispatcher<void()>::SimpleCallback f = [&](){called = true;};
    d.add(f);
    d();
    REQUIRE(called);

}

TEST("simplest dispatcher") {
    Dispatcher d;
    function<panda::optional<int> (Dispatcher::Event&, int)> cb = [](Event& e, int a) -> int {
        return 1 + e.next(a).value_or(0);
    };
    d.add_event_listener(cb);
    d.add_event_listener([](Event& e, int a) -> int {
        return a + e.next(a).value_or(0);
    });
    REQUIRE(d(2).value_or(0) == 3);
}

TEST("remove callback") {
    Dispatcher d;
    d.add_event_listener([](Event& e, int a) -> int {
        return 1 + e.next(a).value_or(0);
    });
    Dispatcher::Callback c = [](Event& e, int a) -> int {
        return a + e.next(a).value_or(0);
    };
    d.add_event_listener(c);
    REQUIRE(d(2).value_or(0) == 3);
    d.remove(c);
    REQUIRE(d(2).value_or(0) == 1);
}

TEST("remove_all in process") {
    Dispatcher d;
    d.add_event_listener([&](Event& e, int a) -> int {
        d.remove_all();
        return 1 + e.next(a).value_or(0);
    });
    d.add_event_listener([](Event&, int) -> int {
        return 2;
    });
    REQUIRE(d(2).value_or(0) == 1);
}

TEST("copy ellision") {
    Dispatcher d;
    Tracer::refresh();
    {
        Dispatcher::Callback cb = Tracer(14);
        d.add_event_listener(cb);
        REQUIRE(d(2).value_or(0) == 16);
        d.remove(cb);
        REQUIRE(d(2).value_or(0) == 0);
    }
    REQUIRE(d(2).value_or(0) == 0);

    REQUIRE(Tracer::ctor_calls == 1); // 1 for temporary object Tracer(10);
    REQUIRE(Tracer::copy_calls == 0);
    REQUIRE(Tracer::move_calls == 1); // 1 construction from tmp object function<int(int)> f = Tracer(10);
    REQUIRE(Tracer::dtor_calls == 2);
}

TEST("callback without event") {
    Dispatcher d;
    bool called = false;
    Dispatcher::SimpleCallback s = [&](int) {
        called = true;
    };
    d.add(s);
    REQUIRE(d(2).value_or(42) == 42);
    REQUIRE(called);
}

TEST("remove callback without event") {
    Dispatcher d;
    bool called = false;
    Dispatcher::SimpleCallback s = [&](int) {
        called = true;
    };
    d.add(s);
    REQUIRE(d(2).value_or(42) == 42);
    REQUIRE(called);
    d.remove(s);
    called = false;
    REQUIRE(d(2).value_or(42) == 42);
    REQUIRE(!called);
}

TEST("remove callback with compatible type") {
    Dispatcher d;
    bool called = false;
    function<void(int16_t)> s = [&](int) {
        called = true;
    };
    d.add(s);
    REQUIRE(d(2).value_or(42) == 42);
    REQUIRE(called);
    d.remove(s);
    called = false;
    REQUIRE(d(2).value_or(42) == 42);
    REQUIRE(!called);
}

TEST("remove callback comparable functor") {
    Dispatcher d;
    static bool called;
    struct S {
        void operator()(int) {
            called = true;
        }
        bool operator ==(const S&) const {
            return true;
        }
    };

    static_assert(panda::has_call_operator<S, int>::value,
                  "S shuld be callable, it can be wrong implementation of panda::has_call_operator or a compiler error");

    S src;
    called = false;
    Dispatcher::SimpleCallback s = src;
    d.add(s);
    CHECK(d(2).value_or(42) == 42);
    CHECK(called);
    d.remove(s);
    called = false;
    CHECK(d(2).value_or(42) == 42);
    CHECK(!called);

    called = false;
    d.add(s);
    CHECK(d(2).value_or(42) == 42);
    CHECK(called);

    d.remove_object(S(src));
    called = false;
    CHECK(d(2).value_or(42) == 42);
    CHECK(!called);
}

TEST("remove callback comparable full functor") {
    Dispatcher d;
    static bool called;
    struct S {
        int operator()(Dispatcher::Event& e, int a) {
            called = true;
            e.next(a);
            return a + 10;
        }
        bool operator ==(const S&) const {
            return true;
        }
    };

    static_assert(panda::has_call_operator<S,Dispatcher::Event&, int>::value,
                  "S shuld be callable, it can be wrong implementation of panda::has_call_operator or a compiler error");

    S src;
    called = false;
    Dispatcher::Callback s = src;
    d.add_event_listener(s);

    CHECK(d(2).value_or(42) == 12);
    CHECK(called);
    called = false;

    SECTION("standatd remove") {
        d.remove(s);
    }

    SECTION("fast remove") {
        d.remove_object(S(src));
    }

    CHECK(d(2).value_or(42) == 42);
    CHECK(!called);
}

TEST("remove simple callback self lambda") {
    Dispatcher d;
    static bool called;
    auto l = [&](panda::Ifunction<void, int>& self, int) {
        d.remove(self);
        called = true;
    };

    Dispatcher::SimpleCallback s = l;
    d.add(s);
    CHECK(d(2).value_or(42) == 42);
    CHECK(called);
    called = false;
    CHECK(d(2).value_or(42) == 42);
    CHECK(!called);
}


TEST("remove callback self lambda") {
    using panda::optional;
    Dispatcher d;
    static bool called;
    auto l = [&](panda::Ifunction<optional<int>, Dispatcher::Event&, int>& self, Dispatcher::Event&, int a) {
        d.remove(self);
        called = true;
        return a + 10;
    };

    Dispatcher::Callback s = l;
    d.add_event_listener(s);
    CHECK(d(2).value_or(42) == 12);
    CHECK(called);
    called = false;
    CHECK(d(2).value_or(42) == 42);
    CHECK(!called);
}

TEST("dispatcher to function conversion") {
    Dispatcher d;
    d.add_event_listener([](Dispatcher::Event&, int a){return a*2;});
    function<panda::optional<int>(int)> f = d;
    REQUIRE(f(10).value_or(0) == 20);
}

TEST("dispatcher 2 string calls") {
    using Dispatcher = CallbackDispatcher<void(string)>;
    Dispatcher d;
    d.add([](string s) {CHECK(s == "value");});
    d.add([](string s) {CHECK(s == "value");});
    d(string("value"));
    string s = "value";
    d(s);
}

TEST("normal(back) order") {
    using Dispatcher = CallbackDispatcher<void()>;
    Dispatcher d;
    std::vector<int> res;
    d.add([&]{ res.push_back(1); });
    d.add([&]{ res.push_back(2); });
    d.add_event_listener([&](Dispatcher::Event& e){ res.push_back(3); e.next(); });
    d();
    REQUIRE(res == std::vector<int>({1,2,3}));
}

TEST("front order") {
    using Dispatcher = CallbackDispatcher<void()>;
    Dispatcher d;
    std::vector<int> res;
    d.prepend_event_listener([&](Dispatcher::Event& e){ res.push_back(1); e.next(); });
    d.add([&]{ res.push_back(2); }, false);
    d.prepend([&]{ res.push_back(3); });
    d();
    REQUIRE(res == std::vector<int>({3,2,1}));
}

TEST("const ref arg move") {
    Tracer::refresh();
    CallbackDispatcher<void(const Tracer&)> d;

    SECTION("many listenees") {
        Tracer::refresh();
        d.add([](auto&&...){});
        d.add([](auto&&...){});
        d.add([](auto&&...){});
    }
    SECTION("no listeners"){}

    d(Tracer());
    CHECK(Tracer::ctor_total() == 1);
}

TEST("lambda self reference auto...") {
    CallbackDispatcher<void(int)> d1;
    CallbackDispatcher<int(int)>  d2;

    auto l1 = [](auto...args) -> void { static_assert(sizeof...(args) == 1, "auto... resolved as without SELF"); };
    auto l2 = [](auto&&...args) -> void { static_assert(sizeof...(args) == 1, "auto... resolved as without SELF"); };
    auto l3 = [](auto&&...args) { REQUIRE(sizeof...(args) == 1); };

    d1.add(l1);
    d1.add(l2);
    d1.add(l3);
    d2.add(l1);
    d2.add(l2);
    d2.add(l3);

    auto l1a = [](auto&, auto...args) -> int { static_assert(sizeof...(args) == 1, "auto... resolved as without SELF"); return 1; };
    auto l2a = [](auto&&...args) -> int { static_assert(sizeof...(args) == 2, "auto... resolved as without SELF"); return 2; };
    auto l3a = [](auto&&...args) { REQUIRE(sizeof...(args) == 2); return 3; };

    d2.add_event_listener(l1a);
    d2.add_event_listener(l2a);
    d2.add_event_listener(l3a);
}

TEST("killing dispatcher") {
    Dispatcher* d = new Dispatcher;
    function<void (int)> cb = [&](int) {
        delete d;
    };
    d->add(cb);

    bool called = false;
    function<void (int)> check = [&](int) {
        called = true;
    };
    d->add(check, true);

    (*d)(10);
    REQUIRE_FALSE(called);
}
