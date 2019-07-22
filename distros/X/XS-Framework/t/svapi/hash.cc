#include "test.h"

using Test = TestSv<Hash>;

TEST_CASE("Hash", "[Sv]") {
    perlvars vars;
    Hash my(vars.hv);
    Sv oth_valid(vars.ohv), oth_invalid(vars.av);

    SECTION("ctor") {
        SECTION("empty") {
            Hash o;
            REQUIRE(!o);
        }
        SECTION("from SV") {
            SECTION("from undef SV")  { Test::ctor(vars.undef, behaviour_t::EMPTY); }
            SECTION("from number SV") { Test::ctor(vars.iv, behaviour_t::THROWS); }
            SECTION("from string SV") { Test::ctor(vars.pv, behaviour_t::THROWS); }
            SECTION("from RV")        { Test::ctor(vars.rv, behaviour_t::THROWS); }
            SECTION("from RV-OAV")    { Test::ctor(vars.oavr, behaviour_t::THROWS); }
            SECTION("from RV-OHV")    { Test::ctor(vars.ohvr, behaviour_t::VALID, (SV*)vars.ohv); }
            SECTION("from AV")        { Test::ctor((SV*)vars.av, behaviour_t::THROWS); }
            SECTION("from HV")        { Test::ctor((SV*)vars.hv, behaviour_t::VALID); }
            SECTION("from SHV")       { Test::ctor((SV*)vars.stash, behaviour_t::VALID); }
            SECTION("from OHV")       { Test::ctor((SV*)vars.ohv, behaviour_t::VALID); }
            SECTION("from CV")        { Test::ctor((SV*)vars.cv, behaviour_t::THROWS); }
        }
        SECTION("from HV") { Test::ctor(vars.hv, behaviour_t::VALID); }

        SECTION("from Hash")       { Test::ctor(my, behaviour_t::VALID); }
        SECTION("from valid Sv")   { Test::ctor(oth_valid, behaviour_t::VALID); }
        SECTION("from invalid Sv") { Test::ctor(oth_invalid, behaviour_t::THROWS); }
        SECTION("from ilist")      {
            Hash o({
                {"key1", Simple(1)},
                {"key2", Simple("val2")},
            });
            REQUIRE(o.size() == 2);
            REQUIRE(Simple(o["key1"]) == 1);
            REQUIRE(Simple(o["key2"]) == "val2");
        }
    }

    SECTION("create") {
        SECTION("empty") {
            auto o = Hash::create();
            REQUIRE(o);
            REQUIRE(o.get());
        }
        SECTION("ilist") {
            auto o = Hash::create({
                {"key1", Simple(1)},
                {"key2", Simple("val2")},
            });
            REQUIRE(o.size() == 2);
            REQUIRE(Simple(o["key1"]) == 1);
            REQUIRE(Simple(o["key2"]) == "val2");
        }
        SECTION("with capacity") {
            auto o = Hash::create(50);
            REQUIRE(o.capacity() >= 50);
        }
    }

    SECTION("operator=") {
        auto o = Hash::create();
        SECTION("SV") {
            SECTION("undef SV")  { Test::assign(o, vars.undef, behaviour_t::EMPTY); }
            SECTION("number SV") { Test::assign(o, vars.iv, behaviour_t::THROWS); }
            SECTION("string SV") { Test::assign(o, vars.pv, behaviour_t::THROWS); }
            SECTION("RV")        { Test::assign(o, vars.rv, behaviour_t::THROWS); }
            SECTION("RV-OAV")    { Test::assign(o, vars.oavr, behaviour_t::THROWS); }
            SECTION("RV-OHV")    { Test::assign(o, vars.ohvr, behaviour_t::VALID, (SV*)vars.ohv); }
            SECTION("AV")        { Test::assign(o, (SV*)vars.av, behaviour_t::THROWS); }
            SECTION("HV")        { Test::assign(o, (SV*)vars.hv, behaviour_t::VALID); }
            SECTION("SHV")       { Test::assign(o, (SV*)vars.stash, behaviour_t::VALID); }
            SECTION("OHV")       { Test::assign(o, (SV*)vars.ohv, behaviour_t::VALID); }
            SECTION("CV")        { Test::assign(o, (SV*)vars.cv, behaviour_t::THROWS); }
        }
        SECTION("HV")         { Test::assign(o, vars.hv, behaviour_t::VALID); }
        SECTION("Hash")       { Test::assign(o, my, behaviour_t::VALID); }
        SECTION("valid Sv")   { Test::assign(o, oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv") { Test::assign(o, oth_invalid, behaviour_t::THROWS); }
    }

    SECTION("set") {
        Hash o;
        o.set(vars.iv); // no checks
        REQUIRE(o);
        REQUIRE(SvREFCNT(vars.iv) == 2);
        REQUIRE(o.get() == vars.iv);
    }

    SECTION("cast") {
        Hash o(vars.hv);
        auto rcnt = SvREFCNT(vars.hv);
        SECTION("to SV") {
            SV* sv = o;
            REQUIRE(sv == (SV*)vars.hv);
            REQUIRE(SvREFCNT(vars.hv) == rcnt);
        }
        SECTION("to HV") {
            HV* sv = o;
            REQUIRE(sv == vars.hv);
            REQUIRE(SvREFCNT(vars.hv) == rcnt);
        }
    }

    SECTION("get") {
        Hash o(vars.hv);
        auto rcnt = SvREFCNT(vars.hv);
        REQUIRE(o.get<>() == (SV*)vars.hv);
        REQUIRE(o.get<SV>() == (SV*)vars.hv);
        REQUIRE(o.get<HV>() == vars.hv);
        REQUIRE(SvREFCNT(vars.hv) == rcnt);
    }

    SECTION("fetch/[]const/[]/at") {
        Hash o;
        const Hash& co = o;
        REQUIRE(!o.fetch("key")); // fetch return empty object when empty
        REQUIRE(!co["key"]);
        REQUIRE(!o.fetch("key"));
        REQUIRE_THROWS(o.at("key"));

        o = Hash::create();
        REQUIRE(!o.fetch("key"));
        REQUIRE(!co["key"]);
        REQUIRE(o["key"]);
        REQUIRE(o.fetch("key"));
        REQUIRE(o.at("key"));
        REQUIRE_THROWS(o.at("nokey"));

        hv_stores(o, "key", newSViv(10));
        hv_stores(o, "name", newSVpvs("vasya"));

        REQUIRE(o.fetch("key"));
        REQUIRE(o.at("key"));
        REQUIRE(Simple(o.fetch("key")).get<int>() == 10);
        REQUIRE(Simple(o.at("key")).get<int>() == 10);
        REQUIRE(Simple(co["name"]) == "vasya");
        REQUIRE(Simple(o["name"]) == "vasya");
        REQUIRE(!o.fetch("nokey"));
        REQUIRE(!co["nokey"]);
        REQUIRE_THROWS(o.at("nokey"));
        REQUIRE(o["nokey"]);
        REQUIRE(co["nokey"]);
        REQUIRE(o.fetch("nokey"));
    }

    SECTION("store/[]=") {
        Hash o;
        REQUIRE_THROWS(o.store("key", Sv()));
        REQUIRE(!o.fetch("key"));

        o = Hash::create();
        auto pcnt = SvREFCNT(vars.pv);
        o.store("key", vars.pv);
        REQUIRE(Simple(o.fetch("key")) == "hello");
        REQUIRE(SvREFCNT(vars.pv) == pcnt+1);

        auto icnt = SvREFCNT(vars.iv);
        o["age"] = vars.iv;
        REQUIRE(o.fetch("age").get() == vars.iv);
        REQUIRE(SvREFCNT(vars.iv) == icnt+1);

        auto rcnt = SvREFCNT(vars.rv);
        o.store("key", vars.rv);
        REQUIRE(o.fetch("key").get() == vars.rv);
        REQUIRE(SvREFCNT(vars.pv) == pcnt);
        REQUIRE(SvREFCNT(vars.rv) == rcnt+1);

        o["age"] = vars.rv;
        REQUIRE(o.fetch("age").get() == vars.rv);
        REQUIRE(SvREFCNT(vars.iv) == icnt);
        REQUIRE(SvREFCNT(vars.rv) == rcnt+2);

        o.store("undef", nullptr);
        REQUIRE(o.fetch("undef"));
        REQUIRE(!o.fetch("undef").defined());
        REQUIRE(o.fetch("undef").use_count() == 2);

        o["u"] = nullptr;
        REQUIRE(o.fetch("u"));
        REQUIRE(!o.fetch("u").defined());
        REQUIRE(o.fetch("u").use_count() == 2);

        o["a"] = Simple(100);
        o["b"] = o["a"];
        REQUIRE(o.fetch("b"));
        REQUIRE(Simple(o.fetch("b")) == 100);

        o.store("c", o["b"]);
        REQUIRE(Simple(o.fetch("c")) == 100);
    }

    SECTION("erase") {
        auto o = Hash::create();
        REQUIRE(!o.erase("key"));
        o["key"] = vars.pv;
        Sv elem = o.erase("key");
        REQUIRE(elem);
        REQUIRE(elem.get() == vars.pv);
        REQUIRE(!o.fetch("key"));
        elem.reset();
    }

    SECTION("exists") {
        Hash o;
        REQUIRE(!o.exists("key"));
        o = Hash::create();
        REQUIRE(!o.exists("key"));
        o["key"] = nullptr;
        REQUIRE(o.exists("key"));
        o.erase("key");
        REQUIRE(!o.contains("key"));
    }

    SECTION("size") {
        Hash o;
        REQUIRE(o.size() == 0);
        o = Hash::create();
        REQUIRE(o.size() == 0);
        o["key"] = nullptr;
        REQUIRE(o.size() == 1);
        o.store("key2", vars.pv);
        REQUIRE(o.size() == 2);
        o["key2"] = vars.iv;
        REQUIRE(o.size() == 2);
    }

    SECTION("clear/undef") {
        Hash o;
        o.clear();
        o.undef();
        REQUIRE(o.size() == 0);
        o = Hash::create();
        o.clear();
        o.undef();
        REQUIRE(o.size() == 0);

        o["key"] = vars.iv;
        REQUIRE(o.size() == 1);
        o.clear();
        REQUIRE(o.size() == 0);
        REQUIRE(!o.exists("key"));

        o["key"] = vars.pv;
        REQUIRE(o.size() == 1);
        o.undef();
        REQUIRE(o.size() == 0);
        REQUIRE(!o.exists("key"));
    }

    SECTION("iterate") {
        Hash o;
        REQUIRE(o.begin() == o.end());
        o = Hash::create();
        REQUIRE(o.begin() == o.end());
        auto icnt = SvREFCNT(vars.iv);
        auto pcnt = SvREFCNT(vars.pv);
        o["key"] = vars.iv;
        o["name"] = vars.pv;
        o["ref"] = vars.rv;
        REQUIRE(SvREFCNT(vars.iv) == icnt+1);

        Hash check = Hash::create();
        int cnt = 0;
        for (auto it = o.begin(); it != o.end(); ++it) {
            cnt++;
            REQUIRE(it->key().length());
            REQUIRE(it->value());
            REQUIRE(it->hash());
            check[it->key()] = it->value();
        }
        REQUIRE(cnt == 3);
        REQUIRE(check.size() == 3);
        REQUIRE(check["key"].get() == vars.iv);
        REQUIRE(check["name"].get() == vars.pv);
        REQUIRE(check["ref"].get() == vars.rv);
        REQUIRE(SvREFCNT(vars.iv) == icnt+2);
        check.clear();
        REQUIRE(SvREFCNT(vars.iv) == icnt+1);

        for (auto it = o.begin(); it != o.end(); ++it) {
            it->value(vars.pv);
        }
        REQUIRE(SvREFCNT(vars.iv) == icnt);
        REQUIRE(SvREFCNT(vars.pv) == pcnt+3);
        REQUIRE(o["key"].get() == vars.pv);
        REQUIRE(o["name"].get() == vars.pv);
        REQUIRE(o["ref"].get() == vars.pv);
    }

    SECTION("const iterate") {
        Hash src;
        const Hash& o = src;
        REQUIRE(o.begin() == o.end());
        src = Hash::create();
        REQUIRE(o.cbegin() == o.cend());
        src["key"] = vars.iv;
        src["name"] = vars.pv;
        src["ref"] = vars.rv;

        Hash check = Hash::create();
        int cnt = 0;
        for (auto it = o.cbegin(); it != o.cend(); ++it) {
            cnt++;
            REQUIRE(it->key().length());
            REQUIRE(it->value());
            REQUIRE(it->hash());
            check[it->key()] = it->value();
        }
        REQUIRE(cnt == 3);
        REQUIRE(check.size() == 3);
        REQUIRE(check["key"].get() == vars.iv);
        REQUIRE(check["name"].get() == vars.pv);
        REQUIRE(check["ref"].get() == vars.rv);
    }

    SECTION("multi-deref") {
        auto o = Hash::create();
        o["key1"] = Ref::create(Array::create({Simple(100)}));
        o["key2"] = Simple(1);
        Simple res = o["key1"][0];
        REQUIRE(res);
        REQUIRE(res == 100);
        o["key1"][0] = Simple(200);
        REQUIRE(o["key1"][0]);
        REQUIRE(Simple(o["key1"][0]) == 200);
        REQUIRE_THROWS(o["key2"][0]);

        auto h = Hash::create();
        h["key"] = Simple(100);
        o.store("key3", Ref::create(h));
        res = o["key3"]["key"];
        REQUIRE(res);
        REQUIRE(res == 100);
        o["key3"]["key"] = Simple(200);
        REQUIRE(o["key3"]["key"]);
        REQUIRE(Simple(o["key3"]["key"]) == 200);
        REQUIRE_THROWS(o["key2"]["key"]);
    }

    SECTION("capacity") {
        Hash o;
        REQUIRE(o.capacity() == 0);
        o = Hash::create();
        o["a"] = Simple(1);
        o["b"] = Simple(1);
        REQUIRE(o.capacity() >= 2);
    }

    SECTION("reserve") {
        auto o = Hash::create();
        o.reserve(100);
        REQUIRE(o.capacity() >= 100);
    }
}
