#include <xs/unievent/Handle.h>

using namespace xs;
using namespace panda::unievent;
using panda::string_view;

MODULE = UniEvent::Handle                PACKAGE = UniEvent::Handle
PROTOTYPES: DISABLE

BOOT {
    Stash stash(__PACKAGE__);
    stash.add_const_sub("UNKNOWN_TYPE", Simple(Handle::UNKNOWN_TYPE.name));
}

Loop* Handle::loop ()

string_view Handle::type () {
    RETVAL = THIS->type().name;
}

bool Handle::active ()

void Handle::reset ()

void Handle::clear ()

bool Handle::weak (bool value = false) {
    if (items > 1) {
        THIS->weak(value);
        XSRETURN_UNDEF;
    }
    RETVAL = THIS->weak();
}

int CLONE_SKIP (...) {
    XSRETURN_YES;
    PERL_UNUSED_VAR(items);
}
