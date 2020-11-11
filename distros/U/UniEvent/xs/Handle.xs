#include <xs/unievent/Handle.h>

using namespace xs;
using namespace panda::unievent;
using panda::string_view;

namespace xs {
namespace unievent {

static std::map<HandleType, SV*>& registered_perl_classes() {
    static std::map<HandleType, SV*> inst;
    return inst;
}

Sv handle_perl_class(const HandleType& type) {
    auto i = registered_perl_classes().find(type);
    if (i == registered_perl_classes().end()) return Stash{};
    else return i->second;
}

void register_perl_class(const HandleType& t, const Stash& st) {
    auto i = registered_perl_classes().find(t);
    if (i != registered_perl_classes().end() && st != i->second) {
        panda::string err = panda::string("Handle type ") + t.name + "is already registered as " + st.name();
        throw std::logic_error(std::string(err.data(), err.length()));
    }
    registered_perl_classes().insert({t, st});
}

}}

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
