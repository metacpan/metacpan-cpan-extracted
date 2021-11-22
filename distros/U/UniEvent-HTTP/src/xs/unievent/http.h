#pragma once
#include <xs/unievent/Tcp.h>
#include <xs/unievent/Ssl.h>
#include <xs/protocol/http.h>
#include <panda/unievent/http.h>
#include <panda/unievent/http/Server.h>
#include <panda/unievent/http/UserAgent.h>

namespace xs { namespace unievent { namespace http {

using namespace panda::unievent::http;

void fill (Request*,           const Hash&);
void fill (Pool::Config&,      const Hash&);
void fill (ServerResponse*,    const Hash&);
void fill (Server::Location&,  const Hash&);
void fill (Server::Config&,    const Hash&);
void fill (UserAgent::Config&, const Hash&);
void fill_form(Request* req,   const Sv& sv);

void fill (Hash&, const Server::Config&);
void fill (Hash&, const Server::Location&);

}}}

namespace xs {


template <class TYPE>
struct Typemap<panda::unievent::http::Request*, TYPE> : Typemap<panda::protocol::http::Request*, TYPE> {
    static panda::string_view package () { return "UniEvent::HTTP::Request"; }
};

template <class TYPE>
struct Typemap<panda::unievent::http::RequestSP, panda::iptr<TYPE>> : Typemap<TYPE*> {
    using Super = Typemap<TYPE*>;
    static panda::iptr<TYPE> in (Sv arg) {
        if (!arg.defined()) return {};
        if (arg.is_object_ref()) return Super::in(arg);
        panda::iptr<TYPE> ret = make_backref<TYPE>();
        xs::unievent::http::fill(ret.get(), arg);
        return ret;
    }
};

template <class TYPE>
struct Typemap<panda::unievent::http::Response*, TYPE> : Typemap<panda::protocol::http::Response*, TYPE> {
    static panda::string_view package () { return "UniEvent::HTTP::Response"; }
};

template <class TYPE>
struct Typemap<panda::unievent::http::Client*, TYPE> : Typemap<panda::unievent::Tcp*, TYPE> {
    static panda::string_view package () { return "UniEvent::HTTP::Client"; }
};

template <class TYPE>
struct Typemap<panda::unievent::http::Pool::Config, TYPE> : TypemapBase<panda::unievent::http::Pool::Config, TYPE> {
    static TYPE in (SV* arg) { TYPE cfg; xs::unievent::http::fill(cfg, arg); return cfg; }
};

template <class TYPE>
struct Typemap<panda::unievent::http::Pool*, TYPE> : TypemapObject<panda::unievent::http::Pool*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMG> {
    static panda::string_view package () { return "UniEvent::HTTP::Pool"; }
};

template <class TYPE>
struct Typemap<panda::unievent::http::RedirectContext*, TYPE> : TypemapObject<panda::unievent::http::RedirectContext*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMG> {
    static panda::string_view package () { return "UniEvent::HTTP::RedirectContext"; }
};

template <class TYPE>
struct Typemap<panda::unievent::http::ServerRequest*, TYPE> : Typemap<panda::protocol::http::Request*, TYPE> {
    static panda::string_view package () { return "UniEvent::HTTP::ServerRequest"; }
};

template <class TYPE>
struct Typemap<panda::unievent::http::ServerResponse*, TYPE> : Typemap<panda::protocol::http::Response*, TYPE> {
    static panda::string_view package () { return "UniEvent::HTTP::ServerResponse"; }
};

template <class TYPE>
struct Typemap<panda::unievent::http::ServerResponseSP, panda::iptr<TYPE>> : Typemap<TYPE*> {
    using Super = Typemap<TYPE*>;
    static panda::iptr<TYPE> in (Sv arg) {
        if (!arg.defined()) return {};
        if (arg.is_object_ref()) return Super::in(arg);
        panda::iptr<TYPE> ret = make_backref<TYPE>();
        xs::unievent::http::fill(ret.get(), arg);
        return ret;
    }
};

template <class TYPE>
struct Typemap<panda::unievent::http::UserAgent*, TYPE> : TypemapObject<panda::unievent::http::UserAgent*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMG> {
    static panda::string_view package () { return "UniEvent::HTTP::UserAgent"; }
};


template <class TYPE> struct Typemap<panda::unievent::http::Server::Location, TYPE> : TypemapBase<panda::unievent::http::Server::Location, TYPE> {
    static TYPE in (SV* arg) { TYPE loc; xs::unievent::http::fill(loc, arg); return loc; }
    static Scalar out(const TYPE& loc, const Sv& proto = {}) {
        (void)proto;
        auto h = Hash::create();
        xs::unievent::http::fill(h, loc);
        return Ref::create(h);
    }
};

template <class TYPE> struct Typemap<panda::unievent::http::Server::Config, TYPE> : TypemapBase<panda::unievent::http::Server::Config, TYPE> {
    static TYPE in (SV* arg) { TYPE cfg; xs::unievent::http::fill(cfg, arg); return cfg; }
    static Scalar out(const panda::unievent::http::Server::Config& cfg, const Sv& proto = {}) {
        (void)proto;
        auto h = Hash::create();
        xs::unievent::http::fill(h, cfg);
        return Ref::create(h);
    }
};

template <class TYPE>
struct Typemap<panda::unievent::http::Server*, TYPE> : TypemapObject<panda::unievent::http::Server*, TYPE, ObjectTypeRefcntPtr, ObjectStorageMGBackref> {
    static panda::string_view package () { return "UniEvent::HTTP::Server"; }
};

}
