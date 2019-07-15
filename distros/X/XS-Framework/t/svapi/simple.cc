#include "test.h"

using Test = TestSv<Simple>;

template <typename T> typename enable_if<is_integral<T>::value && is_signed<T>::value,   T>::type getnum (const SV* sv) { return SvIVX(sv); }
template <typename T> typename enable_if<is_integral<T>::value && is_unsigned<T>::value, T>::type getnum (const SV* sv) { return SvUVX(sv); }
template <typename T> typename enable_if<is_floating_point<T>::value,                    T>::type getnum (const SV* sv) { return SvNVX(sv); }

template <typename T> typename enable_if<is_integral<T>::value && is_signed<T>::value,   T>::type oknumtype (const SV* sv) { return (bool)SvIOK(sv); }
template <typename T> typename enable_if<is_integral<T>::value && is_unsigned<T>::value, T>::type oknumtype (const SV* sv) { return SvUOK(sv) || SvIOK(sv); }
template <typename T> typename enable_if<is_floating_point<T>::value,                    T>::type oknumtype (const SV* sv) { return (bool)SvNOK(sv); }

// when policy = INCREMENT, and SV* declined, do nothing (+1 -1)
// when policy = NONE and SV* declined, it MUST be decremented

template <class T>
static void test_ctor (T val) {
    Simple obj(val);
    REQUIRE(getnum<T>(obj) == val);
}

template <class T>
static void test_assign (T val) {
    Simple obj;
    obj = val;
    REQUIRE(obj);
    REQUIRE(oknumtype<T>(obj));
    REQUIRE(getnum<T>(obj) == val);
    SV* _sv = obj;

    obj = (T)0;
    REQUIRE(oknumtype<T>(_sv));
    REQUIRE(getnum<T>(obj) == 0);
    REQUIRE((SV*)obj == _sv); // keep same SV

    SV* _tmp = sv_2mortal(newSVpvs("hello"));
    obj = _tmp;
    REQUIRE(SvPOK(_tmp));
    obj = val;
    REQUIRE(oknumtype<T>(_tmp));
    REQUIRE(!SvPOK(_tmp));
    REQUIRE(getnum<T>(obj) == val);
    REQUIRE((SV*)obj == _tmp); // keep same SV
}

template <class T>
static void test_set (T val) {
    Simple obj((T)0);
    obj.set(val);
    REQUIRE(obj);
    REQUIRE(oknumtype<T>(obj));
    REQUIRE(getnum<T>(obj) == val);
}

template <class T>
static void test_cast (T val) {
    Simple obj;
    T r = obj;
    REQUIRE(r == (T)0);

    obj = val;
    r = obj;
    REQUIRE(r == val);
}

template <class T>
static void test_get (T val) {
    Simple obj(val);
    REQUIRE(obj.get<T>() == val);
}

template <class T>
static void test_as_string () {
    Simple o;
    REQUIRE(o.as_string<T>() == T());

    o = Sv::create();
    REQUIRE(o.as_string<T>() == T());

    T src("epta");
    o = string_view(src.data(), src.length());
    REQUIRE(o.as_string<T>() == src);
}

TEST_CASE("Simple", "[Sv]") {
    perlvars vars;
    Simple my(vars.iv);
    Sv oth_valid(vars.ov), oth_invalid(vars.av);

    SECTION("ctor") {
        SECTION("empty") {
            Simple obj;
            REQUIRE(!obj);
        }
        SECTION("SV") {
            SECTION("undef")  { Test::ctor(vars.undef, behaviour_t::VALID); }
            SECTION("number") { Test::ctor(vars.iv, behaviour_t::VALID); }
            SECTION("string") { Test::ctor(vars.pv, behaviour_t::VALID); }
            SECTION("OSV")    { Test::ctor(vars.ov, behaviour_t::VALID); }
            SECTION("RV")     { Test::ctor(vars.rv, behaviour_t::THROWS); }
            SECTION("AV")     { Test::ctor((SV*)vars.av, behaviour_t::THROWS); }
            SECTION("HV")     { Test::ctor((SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("CV")     { Test::ctor((SV*)vars.cv, behaviour_t::THROWS); }
            SECTION("GV")     { Test::ctor((SV*)vars.gv, behaviour_t::THROWS); }
        }

        SECTION("Simple")     { Test::ctor(my, behaviour_t::VALID); }
        SECTION("valid Sv")   { Test::ctor(oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv") { Test::ctor(oth_invalid, behaviour_t::THROWS); }

        SECTION("from number") {
            test_ctor((int8_t)-5);
            test_ctor((int16_t)-30000);
            test_ctor((int32_t)1000000000);
            test_ctor(9223372036854775807L);
            test_ctor((uint8_t)255);
            test_ctor((uint16_t)65535);
            test_ctor((uint32_t)4000000000);
            test_ctor(18446744073709551615LU);
            test_ctor(5.5f);
            test_ctor(222222222.222222);
        }
        SECTION("from string_view") {
            Simple obj(string_view("suka"));
            REQUIRE(string_view("suka") == string_view(SvPVX(obj), 4));
            REQUIRE(SvCUR(obj) == 4);
            REQUIRE(obj.is_string());
        }
    }

    SECTION("noinc") {
        SECTION("undef")  { Test::noinc(vars.undef, behaviour_t::VALID); }
        SECTION("number") { Test::noinc(vars.iv, behaviour_t::VALID); }
        SECTION("string") { Test::noinc(vars.pv, behaviour_t::VALID); }
        SECTION("OSV")    { Test::noinc(vars.ov, behaviour_t::VALID); }
        SECTION("RV")     { Test::noinc(vars.rv, behaviour_t::THROWS); }
        SECTION("AV")     { Test::noinc((SV*)vars.av, behaviour_t::THROWS); }
        SECTION("HV")     { Test::noinc((SV*)vars.hv, behaviour_t::THROWS); }
        SECTION("CV")     { Test::noinc((SV*)vars.cv, behaviour_t::THROWS); }
        SECTION("GV")     { Test::noinc((SV*)vars.gv, behaviour_t::THROWS); }
    }

    SECTION("format") {
        Simple obj = Simple::format("pi = %0.2f", 3.14157);
        REQUIRE(obj.as_string() == "pi = 3.14");
    }

    SECTION("operator=") {
        Simple o(10);
        SECTION("SV") {
            SECTION("undef")  { Test::assign(o, vars.undef, behaviour_t::VALID); }
            SECTION("number") { Test::assign(o, vars.iv, behaviour_t::VALID); }
            SECTION("string") { Test::assign(o, vars.pv, behaviour_t::VALID); }
            SECTION("OSV")    { Test::assign(o, vars.ov, behaviour_t::VALID); }
            SECTION("RV")     { Test::assign(o, vars.rv, behaviour_t::THROWS); }
            SECTION("AV")     { Test::assign(o, (SV*)vars.av, behaviour_t::THROWS); }
            SECTION("HV")     { Test::assign(o, (SV*)vars.hv, behaviour_t::THROWS); }
            SECTION("CV")     { Test::assign(o, (SV*)vars.cv, behaviour_t::THROWS); }
            SECTION("GV")     { Test::assign(o, (SV*)vars.gv, behaviour_t::THROWS); }
        }
        SECTION("Simple")     { Test::assign(o, my, behaviour_t::VALID); }
        SECTION("valid Sv")   { Test::assign(o, oth_valid, behaviour_t::VALID); }
        SECTION("invalid Sv") { Test::assign(o, oth_invalid, behaviour_t::THROWS); }
        SECTION("number") {
            test_assign((int8_t)-5);
            test_assign((int16_t)-30000);
            test_assign((int32_t)1000000000);
            test_assign(9223372036854775807L);
            test_assign((uint8_t)255);
            test_assign((uint16_t)65535);
            test_assign((uint32_t)4000000000);
            test_assign(18446744073709551615LU);
            test_assign(5.5f);
            test_assign(222222222.222222);
        }
        SECTION("char*") {
            Simple obj(vars.iv);
            obj = "abcd";
            REQUIRE(string_view("abcd") == string_view(SvPVX(obj), 4));
            REQUIRE(string_view("abcd") == string_view(SvPVX(vars.iv), 4));
            REQUIRE(SvCUR(obj) == 4);
            REQUIRE(obj.is_string());
        }
        SECTION("string_view") {
            Simple obj(vars.iv);
            obj = string_view("abcd");
            REQUIRE(string_view("abcd") == string_view(SvPVX(obj), 4));
            REQUIRE(string_view("abcd") == string_view(SvPVX(vars.iv), 4));
            REQUIRE(SvCUR(obj) == 4);
            REQUIRE(obj.is_string());
        }
    }

    SECTION("set") {
        SECTION("number") {
            test_set((int8_t)-5);
            test_set((int16_t)-30000);
            test_set((int32_t)1000000000);
            test_set(9223372036854775807L);
            test_set((uint8_t)255);
            test_set((uint16_t)65535);
            test_set((uint32_t)4000000000);
            test_set(18446744073709551615LU);
            test_set(5.5f);
            test_set(222222222.222222);
        }
        SECTION("string") {
            Simple o("xxxx");
            o.set("abcd");
            REQUIRE(o.is_string());
            REQUIRE(string_view("abcd") == string_view(SvPVX(o), 4));
            REQUIRE(SvCUR(o) == 4);

            o.set(string_view("suka blya"));
            REQUIRE(o.is_string());
            REQUIRE(string_view("suka blya") == string_view(SvPVX(o), 9));
            REQUIRE(SvCUR(o) == 9);
        }
    }

    SECTION("cast") {
        SECTION("to number") {
            test_cast((int8_t)-5);
            test_cast((int16_t)-30000);
            test_cast((int32_t)1000000000);
            test_cast(9223372036854775807L);
            test_cast((uint8_t)255);
            test_cast((uint16_t)65535);
            test_cast((uint32_t)4000000000);
            test_cast(18446744073709551615LU);
            test_cast(5.5f);
            test_cast(222222222.222222);
        }
        SECTION("to string_view") {
            Simple o;
            REQUIRE(o.c_str() == nullptr);
            REQUIRE((string_view)o == string_view());

            o = Sv::create();
            REQUIRE(strlen(o.c_str()) == 0);
            REQUIRE((string_view)o == string_view());

            const char* src = "epta";
            o = src;
            REQUIRE(strlen(o.c_str()) == 4);
            REQUIRE(!strcmp(o.c_str(), src));
            REQUIRE(o.c_str() != src);
            REQUIRE(strlen(o.get<char*>()) == 4);
            REQUIRE(!strcmp(o.get<char*>(), src));
            REQUIRE(o.get<char*>() != src);
            REQUIRE((string_view)o == string_view(src));
            REQUIRE(((string_view)o).data() != src);
        }
        SECTION("to SV") {
            Simple o(vars.iv);
            auto cnt = SvREFCNT(vars.iv);
            SV* r = o;
            REQUIRE(r == vars.iv);
            REQUIRE(SvREFCNT(vars.iv) == cnt);
        }
    }

    SECTION("as_string") {
        SECTION("string_view")   { test_as_string<std::string_view>(); }
        SECTION("std::string")   { test_as_string<std::string>(); }
        SECTION("panda::string") { test_as_string<panda::string>(); }
    }

    SECTION("get") {
        SECTION("number") {
            test_get((int8_t)-5);
            test_get((int16_t)-30000);
            test_get((int32_t)1000000000);
            test_get(9223372036854775807L);
            test_get((uint8_t)255);
            test_get((uint16_t)65535);
            test_get((uint32_t)4000000000);
            test_get(18446744073709551615LU);
            test_get(5.5f);
            test_get(222222222.222222);
        }
        SECTION("string") {
            Simple o(vars.pv);
            REQUIRE(o.get<char*>() == SvPVX(vars.pv));
            REQUIRE(o.get<string_view>() == string_view("hello"));
            REQUIRE(o.get<string_view>().data() == SvPVX(vars.pv));
        }
        SECTION("SV") {
            Simple o(vars.iv);
            auto cnt = SvREFCNT(vars.iv);
            REQUIRE(o.get<SV>() == vars.iv);
            REQUIRE(SvREFCNT(vars.iv) == cnt);
        }
    }

    SECTION("length") {
        Simple o = vars.pv;
        REQUIRE(o.length() == 5);
        o.length(3);
        REQUIRE(o.length() == 3);
        REQUIRE((std::string_view)o == std::string_view("hel"));
    }

    SECTION("upgrade") {
        Simple o = vars.iv;
        o.upgrade(SVt_PVMG); // upgrade till PVMG works
        REQUIRE(o.type() == SVt_PVMG);
    }

    SECTION("capacity / create with capacity") {
        Simple o = vars.pv;
        REQUIRE(o.capacity() >= 6);
        o = Simple::create(100);
        REQUIRE(o.capacity() >= 100);
        REQUIRE(o.length() == 0);
        char* buf = o.get<char*>();
        *buf++ = 'j';
        *buf++ = 'o';
        *buf++ = 'p';
        *buf++ = 'a';
        *buf++ = 0;
        o.length(4);
        REQUIRE((string_view)o == string_view("jopa"));
    }

    SECTION("shared") {
        Simple o("str");
        Simple o2("str");
        REQUIRE(o.get<char*>() != o2.get<char*>());

        o = Simple::shared("str");
        o2 = Simple::shared("str");
        REQUIRE(o.get<char*>() == o2.get<char*>());
    }

    SECTION("is_shared") {
        Simple o;
        REQUIRE(!o.is_shared());
        o = Simple("hello");
        REQUIRE(!o.is_shared());
        o = Simple::shared("hello");
        REQUIRE(o.is_shared());
    }

    SECTION("hek") {
        auto o = Simple::shared("world");
        auto hek = o.hek();
        REQUIRE(std::string_view(HEK_KEY(hek), HEK_LEN(hek)) == string_view("world"));
    }

    SECTION("hash") {
        Simple o;
        REQUIRE(o.hash() == 0);
        o = "mystring";
        U32 h;
        PERL_HASH(h, "mystring", 8);
        REQUIRE(o.hash() == h);
    }

    SECTION("const operator[]") {
        const Simple o("hello world");
        REQUIRE(o[0] == 'h');
        REQUIRE(o[10] == 'd');
    }

    SECTION("operator[]") {
        Simple o("hello world");
        REQUIRE(o[0] == 'h');
        REQUIRE(o[10] == 'd');
        o[10] = 's';
        REQUIRE(o[10] == 's');
        REQUIRE(o.get<string_view>() == string_view("hello worls"));
    }

    SECTION("at") {
        SECTION("string") {
            Simple o("hello world");
            REQUIRE(o.at(0) == 'h');
            REQUIRE(o.at(10) == 'd');
            REQUIRE_THROWS(o.at(11));
        }
        SECTION("empty obj") {
            Simple o;
            REQUIRE_THROWS(o.at(0));
        }
        SECTION("empty string") {
            Simple o("");
            REQUIRE_THROWS(o.at(0));
        }
        SECTION("number") {
            Simple o(100);
            REQUIRE(o.at(0) == '1');
        }
    }
}
