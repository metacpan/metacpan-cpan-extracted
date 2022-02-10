#include <xs/export.h>
#include <xs/function.h>
#include <xs/unievent/Tcp.h>
#include <xs/typemap/expected.h>
#include <panda/unievent/util.h>
#include <xs/unievent/Resolver.h>
#include <sstream>

using namespace xs;
using namespace xs::unievent;
using namespace panda::unievent;
using panda::string;
using panda::string_view;
using panda::net::SockAddr;

static inline TcpSP create_tcp (const LoopSP& loop, int domain = AF_UNSPEC) {
    TcpSP ret = make_backref<Tcp>(loop, domain);
    ret->connection_factory = [](const StreamSP& srv) {
        TcpSP client = make_backref<Tcp>(srv->loop());
        xs::out(client); // fill backref
        return client;
    };
    return ret;
}

MODULE = UniEvent::Tcp                PACKAGE = UniEvent::Tcp
PROTOTYPES: DISABLE

BOOT {
    Stash s(__PACKAGE__);
    s.inherit("UniEvent::Stream");
    s.add_const_sub("TYPE", Simple(Tcp::TYPE.name));

    xs::exp::create_constants(s, {
        {"IPV6ONLY", Tcp::Flags::IPV6ONLY}
    });
    unievent::register_perl_class(Tcp::TYPE, s);
}

TcpSP Tcp::new (LoopSP loop = {}, int domain = AF_UNSPEC) {
    if (!loop) loop = Loop::default_loop();
    RETVAL = create_tcp(loop, domain);
}

void Tcp::open (Sv sock) {
    XSRETURN_EXPECTED(THIS->open(sv2sock(sock), Ownership::SHARE));
}

void Tcp::bind (string_view host, uint16_t port, AddrInfoHints hints = AddrInfoHints(), unsigned flags = 0) {
    XSRETURN_EXPECTED(THIS->bind(host, port, hints, flags));
}

void Tcp::bind_addr (SockAddr addr, unsigned flags = 0) {
    XSRETURN_EXPECTED(THIS->bind(addr, flags));
}

#// connect($host, $port, [$callback])
#// connect($host, $port, [$timeout, $callback])
#// connect({host, port, hints, addr, callback, timeout, use_cache})
ConnectRequestSP Tcp::connect (Sv host_or_params, uint16_t port = 0, Sv arg3 = Sv(), Sv arg4 = Sv()) {
    --items;
    auto req = THIS->connect();
    double tsec = 0;
    Sub callback;

    if (host_or_params.is_hash_ref()) {
        Hash p = host_or_params;
        string host;
        AddrInfoHints hints;
        SockAddr addr;
        Resolver::RequestSP resolve_request;
        for (const auto& row : p) {
            auto key = row.key();
            if (!key.length()) continue;
            switch (key[0]) {
                case 'h' : if (key == "host")      host     = row.value().as_string();
                      else if (key == "hints")     hints    = xs::in<AddrInfoHints>(row.value());
                      break;
                case 'p' : if (key == "port")      port     = row.value().number(); break;
                case 'c' : if (key == "callback")  callback = row.value(); break;
                case 't' : if (key == "timeout")   tsec     = row.value().number(); break;
                case 'a' : if (key == "addr")      addr     = xs::in<SockAddr>(row.value()); break;
                case 'u' : if (key == "use_cache") req->use_cache(row.value().is_true()); break;
            }
        }
        if (addr) {
            req->to(addr);
        } else {
            req->to(host, port, hints);
        }
    }
    else {
        if (items < 2) throw "port required";
        req->to(xs::in<string>(host_or_params), port);
        if (items >= 4) {
            tsec = Scalar(arg3).number();
            callback = arg4;
        } else if (items == 3 && arg3.defined()) {
            if (arg3.is_sub_ref()) callback = arg3;
            else                   tsec = Scalar(arg3).number();
        }
    }

    req->timeout(tsec*1000);

    if (callback) {
        auto cb = xs::in<Stream::connect_fn>(callback);
        if (cb) req->on_connect(cb);
    }

    req->run();
    RETVAL = req;
}

#// connect_addr($sockaddr, [$callback])
#// connect_addr($sockaddr, [$timeout, $callback])
ConnectRequestSP Tcp::connect_addr (SockAddr addr, Sv arg1 = Sv(), Sv arg2 = Sv()) {
    --items;
    double tsec = 0;
    Sub callback;
    if (items >= 3) {
        tsec = Scalar(arg1).number();
        callback = arg2;
    }
    else if (items == 2 && arg1.defined()) {
        if (arg1.is_sub_ref()) callback = arg1;
        else                   tsec = Scalar(arg1).number();
    }
    auto req = THIS->connect()->to(addr)->timeout(tsec * 1000);
    if (callback) {
        auto cb = xs::in<Stream::connect_fn>(callback);
        if (cb) req->on_connect(cb);
    }
    req->run();
    RETVAL = req;
}

void Tcp::set_nodelay (bool enable) {
    XSRETURN_EXPECTED(THIS->set_nodelay(enable));
}

void Tcp::set_keepalive (bool enable, unsigned delay) {
    XSRETURN_EXPECTED(THIS->set_keepalive(enable, delay));
}

void Tcp::set_simultaneous_accepts (bool enable) {
    XSRETURN_EXPECTED(THIS->set_simultaneous_accepts(enable));
}

#// pair([$loop])
#// pair({ type => [SOCK_STREAM], protocol => [PF_UNSPEC], handle1 => [], handle2 => [], loop => [default loop]})
#// returns ($handle1, $handle2)
void pair (Sv arg = Sv()) {
    int type     = SOCK_STREAM;
    int protocol = PF_UNSPEC;
    TcpSP h1, h2;
    LoopSP loop;

    if (arg.is_object_ref()) {
        loop = xs::in<Loop*>(arg);
    }
    else if (arg.is_hash_ref()){
        Hash params = arg;
        for (const auto& row : params) {
            auto key = row.key();
            if (!key.length()) continue;
            auto val = row.value();
            switch (key[0]) {
                case 't' : if      (key == "type")     type     = SvIV(val); break;
                case 'p' : if      (key == "protocol") protocol = SvIV(val); break;
                case 'h' : if      (key == "handle1")  h1       = xs::in<Tcp*>(val);
                           else if (key == "handle2")  h2       = xs::in<Tcp*>(val);
                           break;
                case 'l' : if      (key == "loop")     loop     = xs::in<Loop*>(val); break;
            }
        }
    }

    if (!loop) loop = Loop::default_loop();
    // although, these don't accept connections, they can be reset(), and used as servers, so we need connection_factory
    if (!h1) h1 = create_tcp(loop);
    if (!h2) h2 = create_tcp(loop);

    auto ret = Tcp::pair(h1, h2, type, protocol);
    if (!ret) throw Error(ret.error());

    mXPUSHs(xs::out(h1).detach());
    mXPUSHs(xs::out(h2).detach());
    XSRETURN(2);
}

std::string Tcp::dump () {
    std::ostringstream os;
    os << *THIS;
    RETVAL = os.str();
}
