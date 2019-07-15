#include <xs.h>
#include <xs/CallbackDispatcher.h>
#include <vector>
#include <map>
#include "../tmtest.h"

using namespace xs;

MODULE = MyTest::Typemap::Object                PACKAGE = MyTest
PROTOTYPES: DISABLE

INCLUDE: single.xsi

INCLUDE: child.xsi

INCLUDE: refcnt.xsi

INCLUDE: static_cast.xsi

INCLUDE: backref.xsi

INCLUDE: join.xsi

INCLUDE: mixin.xsi

INCLUDE: avhv.xsi

INCLUDE: threads.xsi

INCLUDE: foreign.xsi
