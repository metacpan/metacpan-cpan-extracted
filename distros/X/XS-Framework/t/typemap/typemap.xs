#include <xs.h>
#include <vector>
#include <map>
#include "tmtest.h"
#include <panda/error.h>

using namespace xs;
using panda::ErrorCode;

DCnt dcnt;

MODULE = MyTest::Typemap                PACKAGE = MyTest
PROTOTYPES: DISABLE

BOOT {
    XS_BOOT(MyTest__Typemap__Object);
    XS_BOOT(MyTest__Typemap__CD);
}

AV* dcnt () {
    RETVAL = newAV();
    av_push(RETVAL, newSViv(dcnt.c));
    av_push(RETVAL, newSViv(dcnt.perl));
    dcnt.c = 0;
    dcnt.perl = 0;
}

INCLUDE: primitives.xsi

INCLUDE: svrefs.xsi

INCLUDE: const.xsi

INCLUDE: container.xsi

INCLUDE: not_null.xsi

INCLUDE: svapi.xsi

INCLUDE: function.xsi

INCLUDE: error.xsi
