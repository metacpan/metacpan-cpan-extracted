#include <xs.h>

using namespace xs;

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