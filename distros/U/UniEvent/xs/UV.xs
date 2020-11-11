#include <xs/unievent/Backend.h>
#include <panda/unievent/backend/uv.h>

using xs::Stash;
using panda::unievent::backend::Backend;

MODULE = UniEvent::Backend::UV                PACKAGE = UniEvent::Backend
PROTOTYPES: DISABLE

BOOT {
    Stash stash(__PACKAGE__, GV_ADD);
    auto sv = xs::out<Backend*>(panda::unievent::backend::UV);
    SvREFCNT_inc(sv);
    sv.readonly(true);
    newCONSTSUB(stash, "UV", sv);
}
