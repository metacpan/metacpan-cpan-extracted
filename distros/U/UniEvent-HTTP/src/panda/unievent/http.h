#pragma once
#include "http/Pool.h"
#include "http/Request.h"
#include <panda/expected.h>

namespace panda { namespace unievent { namespace http {

struct sync_t {};
static constexpr sync_t sync;

inline void http_request (const RequestSP& req, const LoopSP& loop = {}) {
    Pool::instance(loop ? loop : Loop::default_loop())->request(req);
}

expected<ResponseSP, ErrorCode> http_request_sync (const RequestSP& req);

void http_get (const URISP& uri, const Request::response_fn&, const LoopSP& = {});

expected<ResponseSP, ErrorCode> http_get (const URISP& uri);

inline void http_get (const string& url, const Request::response_fn& cb, const LoopSP& loop = {}) {
    http_get(new URI(url), cb, loop);
}

inline expected<ResponseSP, ErrorCode> http_get (const string& url) {
    return http_get(new URI(url));
}

}}}
