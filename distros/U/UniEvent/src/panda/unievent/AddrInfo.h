#pragma once
#include <ares.h>
#include <iosfwd>
#include <panda/refcnt.h>
#include <panda/net/sockaddr.h>

namespace panda { namespace unievent {

// addrinfo extract, there are fields needed for hinting only
struct AddrInfoHints {
    static constexpr const int PASSIVE     = ARES_AI_PASSIVE;
    static constexpr const int CANONNAME   = ARES_AI_CANONNAME;
    static constexpr const int NUMERICSERV = ARES_AI_NUMERICSERV;

    AddrInfoHints (int family = AF_UNSPEC, int socktype = 0, int proto = 0, int flags = 0) :
        family(family), socktype(socktype), protocol(proto), flags(flags) {}

    AddrInfoHints (const AddrInfoHints& oth) = default;

    bool operator== (const AddrInfoHints& oth) const {
        return family == oth.family && socktype == oth.socktype && protocol == oth.protocol && flags == oth.flags;
    }

    int family;
    int socktype;
    int protocol;
    int flags;
};

struct AddrInfo {
    AddrInfo ()                  : cur(nullptr) {}
    AddrInfo (ares_addrinfo* ai) : src(new DataSource(ai)), cur(ai) {}

    int           flags     () const { return cur->ai_flags; }
    int           family    () const { return cur->ai_family; }
    int           socktype  () const { return cur->ai_socktype; }
    int           protocol  () const { return cur->ai_protocol; }
    net::SockAddr addr      () const { return cur->ai_addr; }
    string_view   canonname () const { return cur->ai_canonname; }
    AddrInfo      next      () const { return AddrInfo(src, cur->ai_next); }
    AddrInfo      first     () const { return AddrInfo(src, src->ai); }

    explicit operator bool () const { return cur; }

    bool operator== (const AddrInfo& oth) const;
    bool operator!= (const AddrInfo& oth) const { return !operator==(oth); }

    bool is (const AddrInfo& oth) const { return cur == oth.cur; }

    std::string to_string ();

private:
    struct DataSource : Refcnt {
        ares_addrinfo* ai;
        DataSource (ares_addrinfo* ai) : ai(ai) {}
        ~DataSource () { ares_freeaddrinfo(ai); }
    };

    iptr<DataSource> src;
    ares_addrinfo*   cur;

    AddrInfo (const iptr<DataSource>& src, ares_addrinfo* cur) : src(src), cur(cur) {}
};

std::ostream& operator<< (std::ostream& os, const AddrInfo& ai);

}}
