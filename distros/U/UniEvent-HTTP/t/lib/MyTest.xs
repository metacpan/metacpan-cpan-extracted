#include "test.h"
#include <xs.h>

using namespace xs;
using namespace panda;
using namespace panda::unievent::http;

MODULE = MyTest                PACKAGE = MyTest
PROTOTYPES: DISABLE

bool variate_ssl (SV* val = nullptr) {
    if (val) secure = SvTRUE(val);
    RETVAL = secure;
}
