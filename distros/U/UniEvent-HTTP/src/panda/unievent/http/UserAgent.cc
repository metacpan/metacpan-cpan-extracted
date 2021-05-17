#include "UserAgent.h"
#include <openssl/ssl.h>

namespace panda { namespace unievent { namespace http {

using namespace panda::protocol::http;

UserAgent::UserAgent(const LoopSP& loop, const string& serialized, const Config& config):
    _pool{Pool::instance(loop)}, _cookie_jar(new CookieJar(serialized)), _config(config) {
}

ClientSP UserAgent::request (const RequestSP& req,  const URISP& context_uri, bool top_level) {
    req->response_event.add([ua = UserAgentSP(this)](auto& req, auto& res, auto& err){
        if (!err) {
            auto now = Date(ua->loop()->now());
            ua->cookie_jar()->collect(*res, req->uri, now);
        }
    });
    req->redirect_event.add([ua = UserAgentSP(this), context_uri, top_level](auto& req, auto& res, auto& redirect_ctx){
        auto& jar = ua->cookie_jar();
        auto now = Date(ua->loop()->now());
        jar->collect(*res, redirect_ctx->uri, now);
        ua->inject(req, context_uri, top_level, now);
    });

    auto now = Date(loop()->now());
    inject(req, context_uri, top_level, now);
    return _pool->request(req);
}

void UserAgent::inject(const RequestSP& req, const URISP& context_uri, bool top_level, const Date& now) noexcept {
    _cookie_jar->populate(*req, context_uri, top_level, now);
    if (!req->headers.has("User-Agent") && _config.identity) req->headers.add("User-Agent", _config.identity.value());
    if (_config.ssl_ctx && !req->ssl_ctx) req->ssl_ctx = _config.ssl_ctx;
    if (_config.proxy && !req->proxy) req->proxy = _config.proxy;
}


string UserAgent::to_string(bool include_session) noexcept {
    auto now = Date(loop()->now());
    return _cookie_jar->to_string(include_session, now);
}


}}}
