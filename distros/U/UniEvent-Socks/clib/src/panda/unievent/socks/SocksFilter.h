#pragma once
#include "error.h"
#include "Socks.h"
#include <panda/unievent/Tcp.h>
#include <iosfwd>

namespace panda { namespace unievent { namespace socks {

using panda::net::SockAddr;

struct SocksFilter;
using SocksFilterSP = iptr<SocksFilter>;

struct SocksFilter : StreamFilter, AllocatedObject<SocksFilter> {
    enum class State {
        initial          = 1,
        connecting_proxy = 2,
        resolving_host   = 3, // cancelable async resolve
        handshake_reply  = 4, // waiting for reply, not cancelable
        auth_reply       = 5,
        connect_reply    = 6,
        parsing          = 7, // something not parsed yet
        error            = 8,
        terminal         = 9
    };
    static constexpr double PRIORITY = 100;
    static const     void*  TYPE;

    SocksFilter (Stream* stream, const SocksSP& socks);
    virtual ~SocksFilter();
    
private:
    SocksSP             socks;
    State               state;
    string              host;
    uint16_t            port;
    AddrInfoHints       hints;
    SockAddr            addr;
    TcpConnectRequestSP connect_request;
    Resolver::RequestSP resolve_request;
    // parser state
    int     cs;
    bool    noauth;
    uint8_t auth_status;
    uint8_t atyp;
    uint8_t rep;

    void listen         () override;
    void tcp_connect    (const TcpConnectRequestSP&) override;
    void handle_connect (const ErrorCode&, const ConnectRequestSP&) override;
    void handle_read    (string&, const ErrorCode&) override;
    void handle_write   (const ErrorCode&, const WriteRequestSP&) override;
    void handle_eof     () override;

    void reset () override;

    void init_parser  ();
    void do_handshake ();
    void do_auth      ();
    void do_resolve   ();
    void do_connect   ();
    void do_connected ();
    void do_eof       ();
    void do_error     (const ErrorCode&);
};

std::ostream& operator<< (std::ostream&, SocksFilter::State);

}}}
