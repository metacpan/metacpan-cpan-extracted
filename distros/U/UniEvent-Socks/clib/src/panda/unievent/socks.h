#pragma once
#include "socks/Socks.h"
#include <panda/string_view.h>
#include <panda/unievent/Tcp.h>

namespace panda { namespace unievent { namespace socks {

void use_socks (const TcpSP& handle, string_view host, uint16_t port = 1080, string_view login = "", string_view passw = "", bool socks_resolve = true);
void use_socks (const TcpSP& handle, const SocksSP& socks);

}}}
