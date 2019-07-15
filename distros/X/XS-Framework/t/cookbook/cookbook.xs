#include <xs.h>
using namespace xs;

MODULE = MyTest::Cookbook                PACKAGE = MyTest::Cookbook
PROTOTYPES: DISABLE

BOOT {
    Stash(__PACKAGE__, GV_ADD).mark_as_loaded("MyTest");
}

INCLUDE: recipe01.xsi

INCLUDE: recipe02.xsi

INCLUDE: recipe03.xsi

INCLUDE: recipe04.xsi

INCLUDE: recipe05.xsi

INCLUDE: recipe06.xsi

INCLUDE: recipe07.xsi

INCLUDE: recipe08.xsi

INCLUDE: recipe09.xsi

INCLUDE: recipe10.xsi

INCLUDE: recipe11.xsi

INCLUDE: recipe12.xsi

INCLUDE: recipe13.xsi
