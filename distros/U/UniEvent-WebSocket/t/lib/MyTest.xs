#include <xs.h>
#include <panda/unievent/websocket.h>

using namespace xs;
using namespace panda;
using namespace panda::unievent::websocket;

extern bool secure;

MODULE = MyTest                PACKAGE = MyTest
PROTOTYPES: DISABLE

bool variate_ssl (SV* val = nullptr) {
    if (val) secure = SvTRUE(val);
    RETVAL = secure;
}
