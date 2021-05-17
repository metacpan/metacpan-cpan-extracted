#pragma once
#include "msg.h"

namespace panda { namespace unievent { namespace http {

struct ServerRequest;

struct ServerResponse : protocol::http::Response {
    struct Builder;

    ServerResponse () : _request(), _completed() {}

    ServerResponse (int code, Headers&& header = Headers(), Body&& body = Body(), bool chunked = false, int http_version = 0, const string& message = {})
        : protocol::http::Response(code, std::move(header), std::move(body), chunked, http_version, message), _request(), _completed()
    {}

    virtual void send_chunk       (const string& chunk);
    virtual void send_final_chunk (const string& chunk = {});

    bool completed () const { return _completed; }

private:
    friend ServerRequest;
    friend struct ServerConnection;

    ServerRequest* _request;
    bool           _completed;

};
using ServerResponseSP = iptr<ServerResponse>;

struct ServerResponse::Builder : protocol::http::Response::BuilderImpl<Builder, ServerResponseSP> {
    Builder () : BuilderImpl(new ServerResponse()) {}
};

}}}
