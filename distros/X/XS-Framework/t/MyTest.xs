#include <xs.h>
#include <panda/exception.h>

using namespace xs;
using panda::string;

MODULE = MyTest                PACKAGE = MyTest
PROTOTYPES: DISABLE

BOOT {
    XS_BOOT(MyTest__Cookbook);
    XS_BOOT(MyTest__Typemap);
}

uint64_t bench_sv_payload_get (int count) {
    RETVAL = 0;
    struct Epta {};
    for (int i = 0; i < count; ++i) {
        RETVAL += (uint64_t)typemap::object::TypemapMarker<Epta>::get();
    }
}

void throw_exception(Sv sv) {
    throw sv;
}

void throw_logic_error() {
    throw std::logic_error("my-logic-error");
}

void throw_backtrace() {
    throw panda::exception("my-error");
}

uint64_t test_leaks1 (string cls, string meth, int cnt) {
    RETVAL = 0;
    for (int i = 0; i < cnt; ++i) {
        Stash stash(cls);
        auto ref = stash.call(meth);
        RETVAL += (uint64_t)ref.get();
    }
}

void call_me(Sub s) {
    s();
}
