#include <xs/uri.h>
#include <xs/unievent.h>
#include <panda/unievent/socks.h>

using xs::Stash;
using namespace xs;
using namespace panda::uri;
using panda::string_view;
using panda::unievent::TcpSP;
using namespace panda::unievent::socks;

MODULE = UniEvent::Socks                PACKAGE = UniEvent::Socks
PROTOTYPES: DISABLE

BOOT {
    Stash error_stash("UniEvent::Socks::Error", GV_ADD);
    error_stash.add_const_sub("socks_error", xs::out(make_error_code(errc::socks_error)));
    error_stash.add_const_sub("category", xs::out<const std::error_category*>(&error_category));
}

void use_socks (xs::nn<TcpSP> handle, Sv host_or_uri, uint16_t port = 1080, string_view login = "", string_view passw = "", bool socks_resolve = true) {
    if (items == 2) {
        auto uri = xs::in<URISP>(host_or_uri);
        SocksSP socks = new Socks(*uri, true);
        use_socks(handle, socks);

    } else {
        use_socks(handle, xs::in<string_view>(host_or_uri), port, login, passw, socks_resolve);
    }
}
