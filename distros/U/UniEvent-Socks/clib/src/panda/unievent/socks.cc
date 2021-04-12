#include "socks.h"
#include "socks/SocksFilter.h"

namespace panda { namespace unievent { namespace socks {

void use_socks (const TcpSP& handle, string_view host, uint16_t port, string_view login, string_view passw, bool socks_resolve) {
    use_socks(handle, new Socks(string(host), port, string(login), string(passw), socks_resolve));
}

void use_socks (const TcpSP& handle, const SocksSP& socks) {
    handle->add_filter(new socks::SocksFilter(handle, socks));
}

}}}
