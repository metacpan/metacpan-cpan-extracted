#include "test.h"

using Test = TestSv<Array>;

TEST_CASE("Array", "[Sv]") {
    perlvars vars;
    Array my(vars.av);
    Sv oth_valid(vars.oav), oth_invalid(vars.hv);

    SECTION("ctor") {
        SECTION("empty") {
            Array o;
            REQUIRE(!o);
        }
        SECTION("from SV") {
            SECTION("from undef SV")  { Test::ctor(vars.undef, behaviour_t::EMPTY); }
            SECTION("from number SV") { Test::ctor(vars.iv, behaviour_t::THROWS); }
            SECTION("from string SV") { Test::ctor(vars.pv, behaviour_t::THROWS); }
            SECTION("from RV")        { Test::ctor(vars.rv, behaviour_t::THROWS); }
            SECTION("from RV-OAV")    { Test::ctor(vars.oavr, behaviour_t::VALID, (SV*)vars.oav); }
            SECTION("from RV-OHV")    { Test::ctor(vars.ohvr, behaviour_t::THROWS); }
            SECTION("from AV")        { Test::ctor((SV*)vars.av, behaviour_t::VALID); }
            SECTION("from OAV")       { Test::ctor((SV*)vars.oav, behaviour_t::VALID); }
            SECTION("from HV")        { Test::ctor((SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("from CV")        { Test::ctor((SV*)vars.cv, behaviour_t::THROWS); }
        }
        SECTION("from AV") { Test::ctor(vars.av, behaviour_t::VALID); }

        SECTION("from Array")      { Test::ctor(my, behaviour_t::VALID); }
        SECTION("from valid Sv")   { Test::ctor(oth_valid, behaviour_t::VALID); }
        SECTION("from invalid Sv") { Test::ctor(oth_invalid, behaviour_t::THROWS); }
        SECTION("from ilist") {
            Array o({Simple(100), Simple(200)});
            REQUIRE(o);
            REQUIRE(o.size() == 2);
            REQUIRE(Simple(o[0]) == 100);
            REQUIRE(Simple(o[1]) == 200);
        }
    }

    SECTION("create empty") {
        auto o = Array::create();
        REQUIRE(o);
        REQUIRE(o.get());
    }

    SECTION("operator=") {
        auto o = Array::create();
        SECTION("SV") {
            SECTION("undef SV")  { Test::assign(o, vars.undef, behaviour_t::EMPTY); }
            SECTION("number SV") { Test::assign(o, vars.iv, behaviour_t::THROWS); }
            SECTION("string SV") { Test::assign(o, vars.pv, behaviour_t::THROWS); }
            SECTION("RV")        { Test::assign(o, vars.rv, behaviour_t::THROWS); }
            SECTION("RV-OAV")    { Test::assign(o, vars.oavr, behaviour_t::VALID, (SV*)vars.oav); }
            SECTION("RV-OHV")    { Test::assign(o, vars.ohvr, behaviour_t::THROWS); }
            SECTION("AV")        { Test::assign(o, (SV*)vars.av, behaviour_t::VALID); }
            SECTION("OAV")       { Test::assign(o, (SV*)vars.oav, behaviour_t::VALID); }
            SECTION("HV")        { Test::assign(o, (SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("CV")        { Test::assign(o, (SV*)vars.cv, behaviour_t::THROWS); }
        }
        SECTION("AV")         { Test::assign(o, vars.av, behaviour_t::VALID); }
        SECTION("Array")      { Test::assign(o, my, behaviour_t::VALID); }
        SECTION("valid Sv")   { Test::assign(o, oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv") { Test::assign(o, oth_invalid, behaviour_t::THROWS); }
    }

    SECTION("set") {
        Array o;
        o.set(vars.iv); // no checks
        REQUIRE(o);
        REQUIRE(SvREFCNT(vars.iv) == 2);
        REQUIRE(o.get() == vars.iv);
    }

    SECTION("cast") {
        Array o(vars.av);
        auto rcnt = SvREFCNT(vars.av);
        SECTION("to SV") {
            SV* sv = o;
            REQUIRE(sv == (SV*)vars.av);
            REQUIRE(SvREFCNT(vars.av) == rcnt);
        }
        SECTION("to AV") {
            AV* sv = o;
            REQUIRE(sv == vars.av);
            REQUIRE(SvREFCNT(vars.av) == rcnt);
        }
    }

    SECTION("get") {
        Array o(vars.av);
        auto rcnt = SvREFCNT(vars.av);
        REQUIRE(o.get<>() == (SV*)vars.av);
        REQUIRE(o.get<SV>() == (SV*)vars.av);
        REQUIRE(o.get<AV>() == vars.av);
        REQUIRE(SvREFCNT(vars.av) == rcnt);
    }

    auto arr = Array::create();
    av_push(arr, newSViv(777));
    av_push(arr, newSVpvs("fuckit"));
    av_store(arr, 9, newSViv(555));
    av_extend(arr, 100-1);

    SECTION("size/top_index") {
        Array o;
        REQUIRE(o.size() == 0);
        REQUIRE(o.top_index() == -1);
        o = Array::create();
        REQUIRE(o.size() == 0);
        REQUIRE(o.top_index() == -1);
        o = arr;
        REQUIRE(o.size() == 10);
        REQUIRE(o.top_index() == 9);
    }

    SECTION("capacity") {
        Array o;
        REQUIRE(o.capacity() == 0);
        o = Array::create();
        REQUIRE(o.capacity() == 0);
        o = arr;
        REQUIRE(o.capacity() >= 100);
    }

    SECTION("[]const") { // unsafe getter
        const Array& o = arr;
        REQUIRE(Simple(o[0]) == 777);
        REQUIRE(Simple(o[1]) == "fuckit");
        REQUIRE(!o[2]);
        REQUIRE(!o[90]);
    }

    SECTION("fetch") { // safe getter
        Array o;
        REQUIRE(!o.fetch(0));
        REQUIRE(!o.fetch(1000));

        o = Array::create();
        REQUIRE(!o.fetch(0));
        REQUIRE(!o.fetch(1000));

        o = arr;
        REQUIRE(Simple(o.fetch(0)) == 777);
        REQUIRE(!o.fetch(2));
        REQUIRE(!o.fetch(90));
        REQUIRE(!o.fetch(900));
    }

    SECTION("at") { // safe getter
        Array o;
        REQUIRE_THROWS(o.at(0));
        REQUIRE_THROWS(o.at(1000));

        o = Array::create();
        REQUIRE_THROWS(o.at(0));
        REQUIRE_THROWS(o.at(1000));

        o = arr;
        REQUIRE(Simple(o.at(0)) == 777);
        REQUIRE_THROWS(o.at(2));
        REQUIRE_THROWS(o.at(90));
        REQUIRE_THROWS(o.at(900));
    }

    SECTION("[]") { // unsafe getter
        Array o = arr;
        REQUIRE(Simple(o[0]) == 777);
        REQUIRE(Simple(o[1]) == "fuckit");
        REQUIRE(!o[2]);
        REQUIRE(!o[90]);
    }

    SECTION("[]=") { // unsafe setter
        Array o = arr;
        o[2] = Simple(333);
        REQUIRE(Simple(o.fetch(2)) == 333);
        auto icnt = SvREFCNT(vars.iv);
        auto pcnt = SvREFCNT(vars.pv);
        o[3] = vars.iv;
        REQUIRE(o[3].get() == vars.iv);
        REQUIRE(SvREFCNT(vars.iv) == icnt+1);
        o[3] = vars.pv;
        REQUIRE(o[3].get() == vars.pv);
        REQUIRE(SvREFCNT(vars.iv) == icnt);
        REQUIRE(SvREFCNT(vars.pv) == pcnt+1);
        o[3] = nullptr;
        REQUIRE(!o[3]);
        REQUIRE(SvREFCNT(vars.pv) == pcnt);

        o[3] = o[2];
        REQUIRE(o.fetch(3));
        REQUIRE(Simple(o.fetch(3)) == 333);
    }

    SECTION("store") { // safe setter
        auto icnt = SvREFCNT(vars.iv);
        auto pcnt = SvREFCNT(vars.pv);

        Array o;
        REQUIRE_THROWS(o.store(0, vars.iv));

        o = arr;
        o.store(0, vars.iv);
        REQUIRE(o[0] == vars.iv);
        REQUIRE(o.size() == 10);
        o.store(5, vars.iv);
        REQUIRE(o[5] == vars.iv);
        REQUIRE(o.size() == 10);
        o.store(10, vars.pv);
        REQUIRE(o[10] == vars.pv);
        REQUIRE(o.size() == 11);
        o.store(95, vars.pv);
        REQUIRE(o[95] == vars.pv);
        REQUIRE(o.size() == 96);
        o.store(1000, vars.pv);
        REQUIRE(o[1000] == vars.pv);
        REQUIRE(o.size() == 1001);
        REQUIRE(o.capacity() >= 1001);
        o.store(0, nullptr);
        o.store(5, nullptr);
        o.store(10, nullptr);
        o.store(95, nullptr);
        o.store(1000, nullptr);
        REQUIRE(!o[0]);
        REQUIRE(SvREFCNT(vars.iv) == icnt);
        REQUIRE(SvREFCNT(vars.pv) == pcnt);

        o[0] = Simple(111);
        o.store(1000, o[0]);
        REQUIRE(Simple(o[1000]) == 111);
    }

    SECTION("reserve") {
        auto o = Array::create();
        REQUIRE(o.capacity() == 0);
        o = Array::create(10);
        REQUIRE(o.capacity() >= 10);
        o.reserve(1000);
        REQUIRE(o.capacity() >= 1000);
    }

    SECTION("resize") {
        auto o = Array::create();
        REQUIRE(o.size() == 0);
        o.resize(10);
        REQUIRE(o.size() == 10);
        REQUIRE(o.capacity() >= 10);

        auto icnt = SvREFCNT(vars.iv);
        o[9] = vars.iv;
        REQUIRE(SvREFCNT(vars.iv) == icnt+1);
        o.resize(9);
        REQUIRE(o.size() == 9);
        REQUIRE(!o.fetch(9));
        REQUIRE(SvREFCNT(vars.iv) == icnt);
    }

    SECTION("exists") {
        Array o;
        REQUIRE(!o.exists(0));
        o = Array::create();
        REQUIRE(!o.exists(0));
        o.reserve(2);
        REQUIRE(!o.exists(0));
        o.resize(2);
        REQUIRE(!o.exists(0));
        o.store(1, vars.iv);
        REQUIRE(!o.exists(0));
        REQUIRE(o.exists(1));
        av_delete(o, 1, 0);
        REQUIRE(!o.exists(1));
    }

    SECTION("del") {
        Array o;
        REQUIRE(!o.del(0));
        o = Array::create();
        REQUIRE(!o.del(0));
        o.reserve(2);
        REQUIRE(!o.del(0));
        o.resize(2);
        REQUIRE(!o.del(0));

        auto icnt = SvREFCNT(vars.iv);
        o[0] = vars.iv;
        REQUIRE(SvREFCNT(vars.iv) == icnt+1);
        o[1] = vars.pv;
        REQUIRE(o.del(0).get() == vars.iv);
        REQUIRE(!o.exists(0));
        REQUIRE(SvREFCNT(vars.iv) == icnt);
    }

    SECTION("create") {
        SECTION("capacity") {
            auto o = Array::create(50);
            REQUIRE(o);
            REQUIRE(o.capacity() >= 50);
        }
        SECTION("from SV**") {
            auto o = Array::create(0, NULL);
            REQUIRE(o.size() == 0);
            o = Array::create(0, NULL, Array::COPY);
            REQUIRE(o.size() == 0);

            auto icnt = SvREFCNT(vars.iv), pcnt = SvREFCNT(vars.pv), rcnt = SvREFCNT(vars.rv);
            SV* args[] = {vars.iv, vars.pv, vars.rv};
            o = Array::create(3, args);
            REQUIRE(o.size() == 3);
            REQUIRE(o[0].get() == vars.iv);
            REQUIRE(o[1].get() == vars.pv);
            REQUIRE(o[2].get() == vars.rv);
            REQUIRE(SvREFCNT(vars.iv) == icnt+1);
            REQUIRE(SvREFCNT(vars.pv) == pcnt+1);
            REQUIRE(SvREFCNT(vars.rv) == rcnt+1);
            o.reset();
            REQUIRE(SvREFCNT(vars.iv) == icnt);
            REQUIRE(SvREFCNT(vars.pv) == pcnt);
            REQUIRE(SvREFCNT(vars.rv) == rcnt);

            o = Array::create(3, args, Array::COPY);
            REQUIRE(o.size() == 3);
            REQUIRE(o[0].get() != vars.iv);
            REQUIRE(o[1].get() != vars.pv);
            REQUIRE(o[2].get() != vars.rv);
            REQUIRE(SvREFCNT(vars.iv) == icnt);
            REQUIRE(SvREFCNT(vars.pv) == pcnt);
            REQUIRE(SvREFCNT(vars.rv) == rcnt);
            REQUIRE(Simple(o[0]) == SvIVX(vars.iv));
            REQUIRE(Simple(o[1]).get<panda::string_view>() == SvPVX(vars.pv));
            REQUIRE(Ref(o[2]).value().get() == SvRV(vars.rv));
        }

        SECTION("from Array") {
            Array from = Array::create();
            from.push(Simple(100));
            auto o = Array::create(from);
            REQUIRE(o);
            REQUIRE(o.size() == 1);
            REQUIRE(o[0] == from[0]);
        }

        SECTION("from ilist") {
            auto o = Array::create({Simple(100), Simple(200)});
            REQUIRE(o);
            REQUIRE(o.size() == 2);
            REQUIRE(Simple(o[0]) == 100);
            REQUIRE(Simple(o[1]) == 200);
        }
    }

    SECTION("shift") {
        Array o;
        REQUIRE(!o.shift());
        o = Array::create();
        REQUIRE(!o.shift());
        auto icnt = SvREFCNT(vars.iv), pcnt = SvREFCNT(vars.pv);
        o.store(1, vars.iv);
        o.store(3, vars.pv);
        REQUIRE(!o.shift());
        REQUIRE(o.size() == 3);
        auto elem = o.shift();
        REQUIRE(o.size() == 2);
        REQUIRE(elem.get() == vars.iv);
        elem.reset();
        REQUIRE(SvREFCNT(vars.iv) == icnt);
        REQUIRE(!o.shift());
        REQUIRE(o.size() == 1);
        elem = o.shift();
        REQUIRE(o.size() == 0);
        REQUIRE(elem.get() == vars.pv);
        elem.reset();
        REQUIRE(SvREFCNT(vars.pv) == pcnt);
        REQUIRE(!o.shift());
        REQUIRE(o.size() == 0);
    }

    SECTION("pop") {
        Array o;
        REQUIRE(!o.pop());
        o = Array::create();
        REQUIRE(!o.pop());
        auto icnt = SvREFCNT(vars.iv), pcnt = SvREFCNT(vars.pv);
        o.store(0, vars.iv);
        o.store(2, vars.pv);
        o.resize(4);
        REQUIRE(!o.pop());
        REQUIRE(o.size() == 3);
        auto elem = o.pop();
        REQUIRE(o.size() == 2);
        REQUIRE(elem.get() == vars.pv);
        elem.reset();
        REQUIRE(SvREFCNT(vars.pv) == pcnt);
        REQUIRE(!o.pop());
        REQUIRE(o.size() == 1);
        elem = o.pop();
        REQUIRE(o.size() == 0);
        REQUIRE(elem.get() == vars.iv);
        elem.reset();
        REQUIRE(SvREFCNT(vars.iv) == icnt);
        REQUIRE(!o.pop());
        REQUIRE(o.size() == 0);
    }

    SECTION("push") {
        auto o = Array::create();
        o.push(Scalar());
        REQUIRE(o.size() == 1);
        REQUIRE(!o[0]);
        auto icnt = SvREFCNT(vars.iv);
        o.push(vars.iv);
        REQUIRE(o.size() == 2);
        REQUIRE(o[1].get() == vars.iv);
        REQUIRE(SvREFCNT(vars.iv) == icnt+1);
        o.push({vars.pv, vars.rv, vars.ovr});
        REQUIRE(o.size() == 5);
        REQUIRE(o[2].get() == vars.pv);
        REQUIRE(o[3].get() == vars.rv);
        REQUIRE(o[4].get() == vars.ovr);
        o.push(List(Array::create({Simple(100), Simple(200)})));
        REQUIRE(o.size() == 7);
        REQUIRE(Simple(o[5]) == 100);
        REQUIRE(Simple(o[6]) == 200);
    }

    SECTION("unshift") {
        auto o = Array::create();
        o.unshift(Scalar());
        REQUIRE(o.size() == 1);
        REQUIRE(!o[0]);
        auto icnt = SvREFCNT(vars.iv);
        o.unshift(vars.iv);
        REQUIRE(o.size() == 2);
        REQUIRE(o[0].get() == vars.iv);
        REQUIRE(SvREFCNT(vars.iv) == icnt+1);
        o.unshift({vars.pv, vars.rv, vars.ovr});
        REQUIRE(o.size() == 5);
        REQUIRE(o[0].get() == vars.pv);
        REQUIRE(o[1].get() == vars.rv);
        REQUIRE(o[2].get() == vars.ovr);
        o.unshift(List(Array::create({Simple(100), Simple(200)})));
        REQUIRE(o.size() == 7);
        REQUIRE(Simple(o[0]) == 100);
        REQUIRE(Simple(o[1]) == 200);
    }

    SECTION("clear/undef") {
        Array o;
        o.clear();
        o.undef();
        REQUIRE(o.size() == 0);
        o = Array::create();
        o.clear();
        o.undef();
        REQUIRE(o.size() == 0);

        auto icnt = SvREFCNT(vars.iv), pcnt = SvREFCNT(vars.pv);
        o.push({vars.iv, vars.pv});
        auto cap = o.capacity();
        REQUIRE(o.size() == 2);
        o.clear();
        REQUIRE(o.size() == 0);
        REQUIRE(!o.exists(0));
        REQUIRE(o.capacity() == cap);
        REQUIRE(SvREFCNT(vars.iv) == icnt);
        REQUIRE(SvREFCNT(vars.pv) == pcnt);

        o.push({vars.iv, vars.pv});
        REQUIRE(o.size() == 2);
        o.undef();
        REQUIRE(o.size() == 0);
        REQUIRE(!o.exists(0));
        REQUIRE(o.capacity() == 0);
        REQUIRE(SvREFCNT(vars.iv) == icnt);
        REQUIRE(SvREFCNT(vars.pv) == pcnt);
    }

    SECTION("iterate") {
        Array o;
        REQUIRE(o.begin() == o.end());
        o = Array::create();
        REQUIRE(o.begin() == o.end());
        auto icnt = SvREFCNT(vars.iv);
        auto pcnt = SvREFCNT(vars.pv);
        o.push({vars.iv, vars.pv, vars.rv});
        REQUIRE(SvREFCNT(vars.iv) == icnt+1);

        auto it = o.begin();
        REQUIRE(it != o.end());
        REQUIRE((*it).get() == vars.iv);
        REQUIRE(it[1].get() == vars.pv);
        REQUIRE(SvREFCNT(vars.iv) == icnt+1);
        ++it;
        REQUIRE(it != o.end());
        REQUIRE((*it).get() == vars.pv);
        REQUIRE(SvREFCNT(vars.pv) == pcnt+1);
        ++it;
        REQUIRE(it != o.end());
        REQUIRE((*it).get() == vars.rv);
        ++it;
        REQUIRE(it == o.end());

        it -= 3;
        *it = vars.pv;
        REQUIRE((*it).get() == vars.pv);
        REQUIRE(SvREFCNT(vars.iv) == icnt);
        REQUIRE(SvREFCNT(vars.pv) == pcnt+2);
    }

    SECTION("const iterate") {
        Array src;
        const Array& o = src;
        REQUIRE(o.begin() == o.end());
        src = Array::create();
        REQUIRE(o.cbegin() == o.cend());
        src.push({vars.iv, vars.pv, vars.rv});

        auto it = o.cbegin();
        REQUIRE(it != o.end());
        REQUIRE((*it).get() == vars.iv);
        REQUIRE(it[1].get() == vars.pv);
        ++it;
        REQUIRE(it != o.end());
        REQUIRE((*it).get() == vars.pv);
        ++it;
        REQUIRE(it != o.cend());
        REQUIRE((*it).get() == vars.rv);
        ++it;
        REQUIRE(it == o.cend());
    }

    SECTION("multi-deref") {
        auto o = Array::create({ Ref::create(Array::create({Simple(100)})), Simple(1) });
        Simple res = o[0][0];
        REQUIRE(res);
        REQUIRE(res == 100);
        o[0][0] = Simple(200);
        REQUIRE(o[0][0]);
        REQUIRE(Simple(o[0][0]) == 200);
        REQUIRE_THROWS(o[1][0]);

        auto h = Hash::create();
        h["key"] = Simple(100);
        o.store(2, Ref::create(h));
        res = o[2]["key"];
        REQUIRE(res);
        REQUIRE(res == 100);
        o[2]["key"] = Simple(200);
        REQUIRE(o[2]["key"]);
        REQUIRE(Simple(o[2]["key"]) == 200);
        REQUIRE_THROWS(o[1]["key"]);
    }

    SECTION("front") {
        Array o;
        REQUIRE(!o.front());
        o = Array::create();
        REQUIRE(!o.front());
        auto v1 = Simple(10);
        o.push(v1);
        REQUIRE(o.front() == v1);
        auto v2 = Simple(111);
        o.unshift(v2);
        REQUIRE(o.front() == v2);
    }

    SECTION("back") {
        Array o;
        REQUIRE(!o.back());
        o = Array::create();
        REQUIRE(!o.back());
        auto v1 = Simple(10);
        o.push(v1);
        REQUIRE(o.back() == v1);
        auto v2 = Simple(111);
        o.push(v2);
        REQUIRE(o.back() == v2);
    }
}
