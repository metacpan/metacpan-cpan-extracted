#include <xs/unievent/Loop.h>
#include <xs/unievent/http.h>

using namespace xs;
using namespace xs::unievent::http;
using namespace panda;
using namespace panda::unievent::http;
using panda::uri::URI;
using panda::net::SockAddr;
using panda::unievent::Loop;
using panda::unievent::LoopSP;
using panda::unievent::TcpSP;
using panda::unievent::SslContext;
using xs::protocol::http::strings_to_sv;
using xs::protocol::http::CookieJar;
using xs::protocol::http::CookieJarSP;

MODULE = UniEvent::HTTP                PACKAGE = UniEvent::HTTP
PROTOTYPES: DISABLE

BOOT {
    Stash stash(__PACKAGE__);
    xs::exp::autoexport(stash);
}

void http_request (xs::nn<RequestSP> request, LoopSP loop = {})

void http_request_sync (xs::nn<RequestSP> request) {
    auto result = http_request_sync(request);
    
    U8 want = GIMME_V;
    if (want == G_VOID) XSRETURN_EMPTY;
    
    if (result) mXPUSHs(xs::out(result.value()).detach());
    else        XPUSHs(&PL_sv_undef);
    
    if (want == G_ARRAY && !result) mXPUSHs(xs::out(result.error()).detach());
}

void http_get (URISP uri, Request::response_fn cb = {}, LoopSP loop = {}) {
    auto builder = Request::Builder().uri(uri).method(Request::Method::Get);
    
    if (cb) {
        http_request(builder.response_callback(cb).build(), loop);
        XSRETURN_EMPTY;
    }
        
    auto result = http_request_sync(builder.build());
    if (result) mXPUSHs(xs::out(result.value()).detach());
    else XPUSHs(&PL_sv_undef);
    
    if (GIMME_V == G_ARRAY && !result) mXPUSHs(xs::out(result.error()).detach());
}

INCLUDE: Error.xsi

INCLUDE: RedirectContext.xsi

INCLUDE: Request.xsi

INCLUDE: Response.xsi

INCLUDE: Client.xsi

INCLUDE: Pool.xsi

INCLUDE: ServerRequest.xsi

INCLUDE: ServerResponse.xsi

INCLUDE: Server.xsi

INCLUDE: UserAgent.xsi

INCLUDE: Plack.xsi
