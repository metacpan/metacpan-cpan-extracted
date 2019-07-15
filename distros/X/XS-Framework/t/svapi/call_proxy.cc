#include "test.h"

TEST_CASE("CallProxy", "[Sv]") {
    perlvars vars;
    Sub sub(vars.cv);

    SECTION("ctors/=") {
        sub.call();
        Sv sv = sub.call();
        sv = sub.call();
        sv = (Sv)sub.call();
        Scalar scalar = sub.call();
        scalar = sub.call();
        scalar = (Scalar)sub.call();

        Simple simple = sub.call();
        simple = sub.call();
        simple = (Simple)sub.call();

        List list = sub.call();
        list = sub.call();
        list = (List)sub.call();

        REQUIRE_THROWS_AS((Ref)sub.call(), std::invalid_argument);
        REQUIRE_THROWS_AS((Array)sub.call(), std::invalid_argument);
        REQUIRE_THROWS_AS((Hash)sub.call(), std::invalid_argument);
        REQUIRE_THROWS_AS((Glob)sub.call(), std::invalid_argument);
        REQUIRE_THROWS_AS((Stash)sub.call(), std::invalid_argument);
        REQUIRE_THROWS_AS((Sub)sub.call(), std::invalid_argument);
        REQUIRE_THROWS_AS((Object)sub.call(), std::invalid_argument);
    }

    SECTION("Ref") {
        SECTION("create") {
            auto r = Ref::create(sub.call());
            REQUIRE(r.value().use_count() == 2);
        }
        SECTION("set value") {
            auto r = Ref::create(Simple(100));
            r.value(sub.call());
            REQUIRE(Simple(r.value()) != 100);
            REQUIRE(r.value().use_count() == 2);
        }
    }

    SECTION("Array") {
        auto a = Array::create();
        a.store(0, sub.call());
        a[0] = sub.call();
        a.push(sub.call());
        a.push({sub.call(), sub.call()});
        a.unshift(sub.call());
        a.unshift({sub.call(), sub.call()});
        *(a.begin()) = sub.call();
    }

    SECTION("Sub") {
        sub.call(sub.call());
        sub.call({sub.call(), sub.call()});
    }

    SECTION("Hash") {
        auto h = Hash::create();
        h.store("key", sub.call());
        h["key"] = sub.call();
        h.begin()->value(sub.call());
    }

    SECTION("Stash") {
        Stash h("testing", GV_ADD);
        h.store("key", sub.call());
        h["key"] = sub.call();
        h.begin()->value(sub.call());
        h.scalar("abc", sub.call());
        REQUIRE_THROWS_AS(h.array("abc", sub.call()), std::invalid_argument);
        REQUIRE_THROWS_AS(h.hash("abc", sub.call()), std::invalid_argument);
        REQUIRE_THROWS_AS(h.sub("abc", sub.call()), std::invalid_argument);
        h.sub("abc", Sub("M1::dummy2"));
        h.call("abc", sub.call());
        h.call("abc", {sub.call(), sub.call()});
    }

    SECTION("Glob") {
        Glob g = Glob::create(vars.stash, "testing");
        g.scalar(sub.call());
        REQUIRE_THROWS_AS(g.array(sub.call()), std::invalid_argument);
        REQUIRE_THROWS_AS(g.hash(sub.call()), std::invalid_argument);
        REQUIRE_THROWS_AS(g.sub(sub.call()), std::invalid_argument);
        g.slot(sub.call());
    }

    SECTION("Object") {
        auto o = Stash("testing").bless(Hash::create());
        o.call("abc", sub.call());
        o.call("abc", {sub.call(), sub.call()});
    }

    SECTION("call") {
        auto o = Stash("M1").bless(Hash::create());
        Object res = o.call("dummy2").call("dummy2");
        REQUIRE(res);
        REQUIRE(res == o);
    }

    SECTION("cast") {
        Sub sub("M1::dummy");
        SECTION("to std::array") {
            std::array<Simple,2> ret = sub.call({ Simple(1), Simple(2) });
            REQUIRE(ret[0] == 5);
            REQUIRE(ret[1] == 10);
        }
        SECTION("to std::tuple") {
            std::tuple<Simple, Scalar> ret = sub.call({ Simple(1), Simple(2) });
            REQUIRE(std::get<0>(ret) == 5);
            REQUIRE(Simple(std::get<1>(ret)) == 10);
        }
    }

    SECTION("as_string") {
        Sub sub("M1::dummy2");
        REQUIRE(sub.call({Simple(111)}).as_string() == panda::string("111"));
        const char* str = "ebanarot";
        auto ret = sub.call({Simple(str)}).as_string();
        REQUIRE(ret == str);
        REQUIRE(ret.data() != str);

        REQUIRE(sub.call().as_string() == panda::string());
        REQUIRE(sub.call({Scalar::undef}).as_string() == panda::string());
        REQUIRE_THROWS_AS(sub.call({Ref::create(Array::create())}).as_string(), std::invalid_argument);
    }

    SECTION("as_number") {
        Sub sub("M1::dummy2");
        REQUIRE(sub.call({Simple(111)}).as_number() == 111);
        REQUIRE(sub.call({Simple(111.7)}).as_number() == 111);
        REQUIRE(sub.call({Simple(111.7)}).as_number<double>() == 111.7);
        REQUIRE(sub.call().as_number() == 0);
        REQUIRE(sub.call({Scalar::undef}).as_number() == 0);
        REQUIRE_THROWS_AS(sub.call({Ref::create(Array::create())}).as_number(), std::invalid_argument);
   }

}
