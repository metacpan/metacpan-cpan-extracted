#pragma once
#include <ares.h>
#include <iosfwd>
#include <panda/refcnt.h>
#include <panda/net/sockaddr.h>

namespace panda { namespace unievent {

// addrinfo extract, there are fields needed for hinting only
struct AddrInfoHints {
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
    AddrInfo (ares_addrinfo* ai) : src(new DataSource(ai)), cur(ai ? ai->nodes : nullptr) {}

    int           flags     () const { return cur->ai_flags; }
    int           family    () const { return cur->ai_family; }
    int           socktype  () const { return cur->ai_socktype; }
    int           protocol  () const { return cur->ai_protocol; }
    net::SockAddr addr      () const { return net::SockAddr(cur->ai_addr, cur->ai_addrlen); }
    string_view   canonname () const { return (src->ai && src->ai->cnames) ? src->ai->cnames->name : ""; }
    int           ttl       () const { return cur->ai_ttl; }
    AddrInfo      next      () const { return cur ? AddrInfo(src, cur->ai_next) : AddrInfo{}; }
    AddrInfo      first     () const { return AddrInfo(src, src->ai->nodes); }

    explicit operator bool () const { return cur; }

    bool operator== (const AddrInfo& oth) const;
    bool operator!= (const AddrInfo& oth) const { return !operator==(oth); }

    bool is (const AddrInfo& oth) const { return cur == oth.cur; }

    std::string to_string ();

private:
    struct DataSource : Refcnt {
        ares_addrinfo* ai;
        DataSource (ares_addrinfo* ai) : ai(ai) {}
        ~DataSource () { if (ai) ares_freeaddrinfo(ai); }
    };

    iptr<DataSource> src;
    ares_addrinfo_node*  cur;

    AddrInfo (const iptr<DataSource>& src, ares_addrinfo_node*  nodes) : src(src), cur(nodes) {}
};

std::ostream& operator<< (std::ostream&, const AddrInfo&);
std::ostream& operator<< (std::ostream&, const AddrInfoHints&);

}}
