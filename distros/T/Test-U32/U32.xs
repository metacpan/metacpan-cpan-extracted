#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int check_u32() {
    U32 my_u32 = 0xFFFFffff;
    my_u32 <<= 4;
    my_u32 >>= 4;
    return (my_u32 == 0xFFFFffff ? 0 : 1);
}

MODULE = Test::U32        PACKAGE = Test::U32

int
check_u32()

