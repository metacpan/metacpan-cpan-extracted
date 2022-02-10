#pragma once
#include <cstdint>
#include <deque>
#include "ServerRequest.h"
#include "panda/error.h"
#include "panda/unievent/forward.h"
#include <panda/unievent/Stream.h>
#include <panda/protocol/http/RequestParser.h>

namespace panda { namespace unievent { namespace http {

struct Server;

struct ServerConnection : Refcnt, private IStreamSelfListener, private protocol::http::RequestParser::IFactory {
    struct IFactory {
        virtual ServerRequestSP new_request (ServerConnection*) = 0;
    };

    struct Config {
        uint32_t  idle_timeout;
        uint64_t  max_keepalive_requests;
        size_t    max_headers_size;
        size_t    max_body_size;
        IFactory* factory;
    };

    ServerConnection (Server*, uint64_t id, const Config&, const StreamSP&);

    ~ServerConnection () {}

    uint64_t id () const { return _id; }

    void start        ();
    void close        (const ErrorCode& err) { do_close(err, false); }
    void shutdown     (const ErrorCode& err) { do_close(err, true); }
    void graceful_stop();

    bool is_secure () const { return stream->is_secure(); }

    excepted<net::SockAddr, ErrorCode> sockaddr () const { return stream->sockaddr(); }
    excepted<net::SockAddr, ErrorCode> peeraddr () const { return stream->peeraddr(); }
    
    uint64_t establish_time() const { return _establish_time; }

private:
    friend ServerRequest; friend ServerResponse;
    
    enum class State { Running, Closing, ShuttingDown };

    using RequestParser = protocol::http::RequestParser;
    using Requests      = std::deque<ServerRequestSP>;

    Server*       server;
    uint64_t      _id;
    StreamSP      stream;
    IFactory*     factory;
    RequestParser parser;
    Requests      requests;
    uint64_t      requests_processed = 0;
    uint32_t      idle_timeout;
    uint64_t      max_keepalive_requests;
    TimerSP       idle_timer;
    bool          closing  = false;
    bool          stopping = false;
    uint64_t      _establish_time;

    protocol::http::RequestSP new_request () override;

    void on_connection(const StreamSP&, const ErrorCode&) override;
    void on_read      (string&, const ErrorCode&) override;
    void on_write     (const ErrorCode&, const WriteRequestSP&) override;
    void on_shutdown  (const ErrorCode&, const ShutdownRequestSP&) override;
    void on_eof       () override;

    void request_error(const ServerRequestSP&, const ErrorCode& err);

    void respond            (const ServerRequestSP&, const ServerResponseSP&);
    void write_next_response();
    void send_continue      (const ServerRequestSP&);
    void send_chunk         (const ServerResponseSP&, const string& chunk);
    void send_final_chunk   (const ServerResponseSP&, const string& chunk);
    void finish_request     ();
    void cleanup_request    ();
    void drop_requests      (const ErrorCode&);
    void check_if_idle      ();
    
    void do_close(const ErrorCode&, bool soft);

    StreamSP upgrade(const ServerRequest*);

    ServerResponseSP default_error_response(int code);
};
using ServerConnectionSP = iptr<ServerConnection>;

}}}
