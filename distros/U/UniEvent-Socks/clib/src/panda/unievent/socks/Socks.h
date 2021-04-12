#pragma once
#include "error.h"
#include <panda/string.h>
#include <panda/uri/socks.h>
#include <panda/unievent/error.h>

namespace panda { namespace unievent { namespace socks {

struct Socks : virtual Refcnt {
    using URI = panda::uri::URI;

    static constexpr int MAX_LOGPASS_LENGTH = 255;

    Socks (const string& host, uint16_t port, const string& login = "", const string& passw = "", bool socks_resolve = true)
            : host(host), port(port), login(login), passw(passw), socks_resolve(socks_resolve)
    {
        if (login.length() > MAX_LOGPASS_LENGTH) throw Error("Bad login length");
        if (passw.length() > MAX_LOGPASS_LENGTH) throw Error("Bad password length");
    }

    Socks (const URI::socks& uri, bool socks_resolve = true) : Socks(uri.host(), uri.port(), uri.user(), uri.password(), socks_resolve) {}

    bool configured () const { return !host.empty(); }
    bool loginpassw () const { return !login.empty(); }

    string   host;
    uint16_t port;
    string   login;
    string   passw;
    bool     socks_resolve;
};

using SocksSP = iptr<Socks>;

}}}
