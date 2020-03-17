#include <xs/export.h>
#include <xs/unievent/Resolver.h>

using namespace xs;
using namespace panda::unievent;
using panda::net::SockAddr;

MODULE = UniEvent::Resolver                PACKAGE = UniEvent::Resolver
PROTOTYPES: DISABLE

BOOT {
    Stash s(__PACKAGE__);
    xs::exp::create_constants(s, {
        {"PASSIVE",     AddrInfoHints::PASSIVE    },
        {"NUMERICSERV", AddrInfoHints::NUMERICSERV},
        {"CANONAME",    AddrInfoHints::CANONNAME  }
    });
}

Resolver* Resolver::new (Loop* loop = Loop::default_loop(), Hash hcfg = Hash()) {
    Resolver::Config cfg;
    if (hcfg.size()) {
        Simple val;
        if ((val = hcfg.fetch("cache_expiration_time"))) cfg.cache_expiration_time = val;
        if ((val = hcfg.fetch("cache_limit")))           cfg.cache_limit           = val;
        if ((val = hcfg.fetch("query_timeout")))         cfg.query_timeout         = val.get<double>() * 1000;
        if ((val = hcfg.fetch("workers")))               cfg.workers               = val;
    }
    RETVAL = make_backref<Resolver>(loop, cfg);
}

#// resolve($node, $callback, [$timeout])
#// resolve({node => ..., callback => ..., timeout => ..., service => ..., use_cache => ..., hints => ...})
Resolver::RequestSP Resolver::resolve (Sv node_or_params, SV* callback = NULL, double timeout = Resolver::DEFAULT_RESOLVE_TIMEOUT / 1000) {
    Resolver::RequestSP req = make_backref<Resolver::Request>();
    Sub cb;
    
    if (node_or_params.is_hash_ref()) {
        const Hash h = node_or_params;
        for (const auto& row : h) {
            auto key = row.key();
            if (!key.length()) continue;
            auto sv = row.value();
            switch (key[0]) {
                case 'n': if (key == "node")       req->node   (Simple(sv).as_string());    break;
                case 't': if (key == "timeout")    req->timeout(xs::in<double>(sv) * 1000); break;
                case 's': if (key == "service")    req->service(Simple(sv).as_string());    break;
                case 'p': if (key == "port")       req->port(Simple(sv));                   break;
                case 'h': if (key == "hints")      req->hints  (xs::in<AddrInfoHints>(sv)); break;
                case 'u': if (key == "use_cache")  req->use_cache(sv.is_true());            break;
                case 'o': if (key == "on_resolve") cb = sv;                                 break;
            }
        }
    } else {
        req->node(Simple(node_or_params).as_string());
        cb = callback;
        req->timeout(timeout * 1000);
    }
    
    if (cb) req->on_resolve([cb](const AddrInfo& addr, const std::error_code& err, const Resolver::RequestSP& req) {
        panda_mlog_verbose_debug(uelog, "xs on_resolve");
        auto salistref = Scalar::undef;
        if (!err) {
            auto salist = Array::create();
            for (auto ai = addr; ai; ai = ai.next()) {
                salist.push(xs::out(ai.addr()));
            }
            salistref = Ref::create(salist);
        }
        cb.call<void>(salistref, xs::out(err), xs::out(req));
    });
    
    THIS->resolve(req);
    
    RETVAL = req;
}

uint32_t Resolver::cache_expiration_time (Sv newval = Sv()) {
    if (newval) {
        THIS->cache_expiration_time(Simple(newval));
        XSRETURN_UNDEF;
    }
    RETVAL = THIS->cache_expiration_time();
}

size_t Resolver::cache_limit (Sv newval = Sv()) {
    if (newval) {
        THIS->cache_limit(Simple(newval));
        XSRETURN_UNDEF;
    }
    RETVAL = THIS->cache_limit();
}

size_t Resolver::cache_size ()

size_t Resolver::queue_size ()

void Resolver::clear_cache ()

void Resolver::reset ()

AddrInfoHints hints (int family, int socktype, int protocol = 0, int flags = 0) {
    RETVAL = AddrInfoHints(family, socktype, protocol, flags);
}


MODULE = UniEvent::Resolver                PACKAGE = UniEvent::Resolver::Request
PROTOTYPES: DISABLE

void Resolver::Request::cancel ()
