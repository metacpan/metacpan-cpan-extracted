#include "lib/test.h"
#include <thread>

TEST_PREFIX("resolver: ", "[resolver]");

namespace {
    static int dcnt = 0;
    static int ccnt = 0;
    static auto full = getenv("TEST_FULL");

    struct Vars {
        AsyncTest             test;
        ResolverSP            resolver;
        std::vector<AddrInfo> res;
        Resolver::resolve_fn  success_cb;
        Resolver::resolve_fn  canceled_cb;
        Resolver::resolve_fn  noop_cb = [](auto...) {};

        Vars (unsigned expected_cnt) : test(2000, expected_cnt) {
            ccnt = dcnt = 0;

            resolver = new Resolver(test.loop);

            success_cb = [this](auto& ai, auto& err, auto&) {
                test.happens();
                CHECK(!err);
                CHECK(ai);
                res.push_back(ai);
            };

            canceled_cb = [this](auto& ai, auto& err, auto) {
                test.happens();
                CHECK(err == std::errc::operation_canceled);
                CHECK(!ai);
            };
        }
    };
}

TEST("no cache") {
    Vars v(2);
    auto req = v.resolver->resolve()->node("localhost")->on_resolve(v.success_cb);

    req->use_cache(false);

    req->run();
    v.test.run();
    CHECK(v.resolver->cache().size() == 0);

    req->run();
    v.test.run();
    CHECK(v.resolver->cache().size() == 0);
    CHECK(!v.res[0].is(v.res[1])); // without cache every resolve is executed
    CHECK(v.res[0] == v.res[1]); // but result is the same
}

TEST("cache") {
    Vars v(2);
    auto req = v.resolver->resolve()->node("localhost")->on_resolve(v.success_cb);

    SECTION("no hints") {
        // Resolver will use cache by default, first time it is not in cache, async call
        req->run();
        v.test.run();
        CHECK(v.resolver->cache().size() == 1);

        // in cache, so the call is sync
        req->run();
        v.test.run_nowait();
        CHECK(v.resolver->cache().size() == 1);
        CHECK(v.res[0].is(v.res[1]));
    }

    SECTION("both empty hints") {
        req->hints(AddrInfoHints());

        req->run();
        v.test.run();
        CHECK(v.resolver->cache().size() == 1);

        req->run();
        v.test.run_nowait();
        CHECK(v.resolver->cache().size() == 1);
        CHECK(v.res[0].is(v.res[1]));
    }

    SECTION("custom hints and empty hints") {
        req->hints(AddrInfoHints(AF_INET));

        req->run();
        v.test.run();
        CHECK(v.resolver->cache().size() == 1);

        req->hints(AddrInfoHints());
        req->run();
        v.test.run();
        CHECK(v.resolver->cache().size() == 2);
        CHECK(!v.res[0].is(v.res[1]));
    }

    SECTION("different hints") {
        req->hints(AddrInfoHints(AF_INET));

        req->run();
        v.test.run();
        CHECK(v.resolver->cache().size() == 1);

        req->hints(AddrInfoHints(AF_INET, SOCK_STREAM));
        req->run();
        v.test.run();
        CHECK(v.resolver->cache().size() == 2);
        CHECK(!v.res[0].is(v.res[1]));
    }
}

TEST("service/port") {
    Vars v(2);
    auto req = v.resolver->resolve()->node("localhost")->on_resolve(v.success_cb);

    req->service("80");
    req->run();
    v.test.run();
    CHECK(v.resolver->cache().size() == 1);

    req->service("");
    req->port(80);
    req->run();
    v.test.run();
    CHECK(v.resolver->cache().size() == 1);
    CHECK(v.res[0].is(v.res[1]));

    for (auto ai = v.res[0]; ai; ai = ai.next()) {
        auto addr = ai.addr();
        CHECK(addr.port() == 80);
        if      (addr.is_inet4()) CHECK(addr.ip() == "127.0.0.1");
        else if (addr.is_inet6()) CHECK(addr.ip() == "::1");
    }
}

TEST("cache limit") {
    Vars v(3);
    ResolverSP resolver = new Resolver(v.test.loop, 500, 2);
    auto req = resolver->resolve()->node("localhost")->on_resolve(v.success_cb);

    req->port(80);
    req->run();
    v.test.run();
    CHECK(resolver->cache().size() == 1);

    req->port(443);
    req->run();
    v.test.run();
    CHECK(resolver->cache().size() == 2);

    req->port(22);
    req->run();
    v.test.run();
    CHECK(resolver->cache().size() == 1);
}

TEST("timeout") {
    Vars v(2);
    Resolver::Config cfg;
    cfg.workers = 1;
    cfg.query_timeout = 50;
    ResolverSP resolver = new Resolver(v.test.loop, cfg);

    // will not make it
    resolver->resolve("ya.ru", [&](auto& ai, auto& err, auto) {
        v.test.happens();
        CHECK(err == std::errc::timed_out);
        CHECK(!ai);
    }, 1);

    // put next request to worker to be processed after timeout
    resolver->resolve("localhost", v.success_cb, 1000);

    std::this_thread::sleep_for(std::chrono::milliseconds(51));

    v.test.run();
    CHECK(resolver->cache().size() == 1);
}

TEST("ares query timeout") {
    Vars v(10);
    Resolver::Config cfg;
    cfg.workers = 10;
    cfg.query_timeout = 1;
    ResolverSP resolver = new Resolver(v.test.loop, cfg);

    for (int i = 0; i < 10; ++i) resolver->resolve("ya.ru", [&](auto...) {
        v.test.happens();
    }, 1000);

    v.test.run();
}

TEST("cancel") {
    Vars v(1);
    Resolver::RequestSP req;

    SECTION("not cached") {
        SECTION("ares-async") {
            req = v.resolver->resolve("tut.by", v.canceled_cb);
            SECTION("sync") {
                req->cancel();
            }
            SECTION("async") {
                v.test.loop->delay([=]{
                    req->cancel();
                });
            }
        }
        SECTION("ares-sync") {
            SECTION("sync") {
                req = v.resolver->resolve("localhost", v.canceled_cb);
                req->cancel();
            }
            SECTION("async") {
                v.test.loop->delay([&]{
                    req->cancel();
                });
                req = v.resolver->resolve("localhost", v.canceled_cb);
            }
        }
    }
    SECTION("cached") {
        v.resolver->resolve("localhost", v.noop_cb);
        v.test.run();
        CHECK(v.resolver->cache().size() == 1);

        SECTION("sync") {
            req = v.resolver->resolve("localhost", v.canceled_cb);
            req->cancel();
        }
        SECTION("async") {
            v.test.loop->delay([&]{
                req->cancel();
            });
            req = v.resolver->resolve("localhost", v.canceled_cb);
        }
    }

    v.test.run();

    req->cancel(); // should be no-op
}

TEST("reset") {
    Vars v(0);
    Resolver::RequestSP req;

    SECTION("not cached") {
        v.test.set_expected(3);
        req = v.resolver->resolve("lenta.ru", v.canceled_cb);
        v.resolver->resolve("mail.ru", v.canceled_cb);

        SECTION("sync") {
            v.resolver->resolve("localhost", v.canceled_cb);
            v.resolver->reset();
        }
        SECTION("async") {
            v.test.loop->delay([&]{
                v.resolver->reset();
            });
            v.resolver->resolve("localhost", v.canceled_cb); // our delay must be the first
        }
    }

    SECTION("cached") {
        v.test.set_expected(1);
        v.resolver->resolve("localhost", v.noop_cb);
        v.test.run();
        CHECK(v.resolver->cache().size() == 1);
        SECTION("sync") {
            req = v.resolver->resolve("localhost", v.canceled_cb);
            v.resolver->reset();
        }
        SECTION("async") {
            v.test.loop->delay([&]{
                v.resolver->reset();
            });
            req = v.resolver->resolve("localhost", v.canceled_cb);
        }
    }

    v.test.run();
    req->cancel(); // should not die
}

TEST("hold resolver while active request") {
    Vars v(1);

    struct MyResolver : Resolver {
        MyResolver (const LoopSP& loop) : Resolver(loop) { ++ccnt; }
        ~MyResolver () { ++dcnt; }
    };

    ResolverSP resolver = new MyResolver(v.test.loop);
    resolver->resolve("localhost", [&](auto&, auto& err, auto& req) {
        v.test.happens();
        CHECK(!err);
        CHECK(req->resolver()->loop());
    });
    resolver = nullptr;
    CHECK(dcnt == 0);
    v.test.run();
    CHECK(dcnt == 1);
}

TEST("hold loop while active request (for loop resolver)") {
    Vars v(1);

    struct MyLoop : Loop {
        MyLoop  () { ++ccnt; }
        ~MyLoop () override { ++dcnt; }
    };

    LoopSP loop = new MyLoop();
    Loop* l = loop.get();
    loop->resolver()->resolve("localhost", [&](auto&, auto& err, auto& req) {
        v.test.happens();
        CHECK(!err);
        CHECK(req->resolver()->loop()->resolver());
    });
    loop = nullptr;
    CHECK(dcnt == 0);
    l->run();
    CHECK(dcnt == 1);
}

TEST("many requests") {
    unsigned cnt = 50;
    Vars v(cnt);
    string node;
    SECTION("local") {
        node = "localhost";
        SECTION("cached")     {}
        SECTION("not cached") { v.resolver->cache_limit(0); }
    }
    if (full) SECTION("remote") {
        node = "ya.ru";
        SECTION("cached")     {}
        SECTION("not cached") { v.resolver->cache_limit(0); }
    }
    for (size_t i = 0; i < cnt; ++i) v.resolver->resolve(node, v.success_cb);
    v.test.run();
    CHECK(v.res.size() == cnt);
}

TEST("exception safety") {
    Vars v(2);

    for (int i = 0; i < 2; ++i) {
        v.test.loop->resolver()->resolve("localhost", [&](auto...) {
            v.test.happens();
            throw "epta";
        });
        REQUIRE_THROWS(v.test.run());
    }
}

TEST("sync_resolve exception") {
    Vars v(0);
    REQUIRE_THROWS( sync_resolve(v.test.loop->backend(), "sukanahblya", 12345) );
}

static inline int ai_size (const AddrInfo& ai) {
    int cnt = 0;
    for (auto cur = ai; cur; cur = cur.next()) ++cnt;
    return cnt;
}

TEST("mark bad address") {
    Vars v(1);
    string node = "google.com";

    v.resolver->resolve(node, v.success_cb);
    v.test.run();

    CHECK(v.resolver->cache().size() == 1);
    auto list = v.resolver->find(node);

    int cnt = ai_size(list);

    AddrInfo cur = list;
    for (int i = 1; i <= cnt; ++i) {
        v.resolver->cache().mark_bad_address(node, cur.addr());
        auto ret = v.resolver->find(node);
        if (i < cnt) {
            CHECK(ret != cur);
            cur = cur.next();
            CHECK(ret == cur);
        } else {
            CHECK(ret == list);
        }
    }

    CHECK(ai_size(v.resolver->find(node)) == cnt);
    v.resolver->cache().mark_bad_address(node, net::SockAddr::Inet4("1.1.1.1", 0)); // must be ignored, because this sockaddr is not current addr
    CHECK(ai_size(v.resolver->find(node)) == cnt);
}

TEST("resolver does not crash the loop resolver is held and the loop is gone") {
    LoopSP loop = new Loop();
    ResolverSP resolver = loop->resolver();
    loop.reset();
    CHECK_THROWS_AS(resolver->resolve("localhost", [&](auto...) {}), Error);
}
