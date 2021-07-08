#include <xs.h>
#include <panda/unievent/http.h>

using namespace xs;
using namespace panda;
using namespace panda::unievent::http;

extern bool secure;

MODULE = MyTest                PACKAGE = MyTest
PROTOTYPES: DISABLE

bool variate_ssl (SV* val = nullptr) {
    if (val) secure = SvTRUE(val);
    RETVAL = secure;
}
