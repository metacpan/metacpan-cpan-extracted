#include "ServerConnection.h"
#include "Server.h"
#include "msg.h" // for uehtlog
#include <panda/unievent/Tcp.h>
#include <panda/unievent/Pipe.h>

namespace panda { namespace unievent { namespace http {

excepted<net::SockAddr, ErrorCode> get_sockaddr (const Stream* stream) {
    if (stream->type() == Tcp::TYPE) return panda::dyn_cast<const Tcp*>(stream)->sockaddr();

    auto res = panda::dyn_cast<const Pipe*>(stream)->sockname();
    if (!res) return make_unexpected(res.error());
    #ifndef _WIN32
    return net::SockAddr::Unix(res.value());
    #else
    return {};
    #endif
}

excepted<net::SockAddr, ErrorCode> get_peeraddr (const Stream* stream) {
    if (stream->type() == Tcp::TYPE) return panda::dyn_cast<const Tcp*>(stream)->peeraddr();

    auto res = panda::dyn_cast<const Pipe*>(stream)->peername();
    if (!res) return make_unexpected(res.error());
    #ifndef _WIN32
    return net::SockAddr::Unix(res.value());
    #else
    return {};
    #endif
}

ServerConnection::ServerConnection (Server* server, uint64_t id, const Config& conf, const StreamSP& stream)
    : server(server), _id(id), stream(stream), factory(conf.factory), parser(this), idle_timeout(conf.idle_timeout),
      max_keepalive_requests(conf.max_keepalive_requests)
{
    stream->event_listener(this);

    parser.max_headers_size = conf.max_headers_size;
    parser.max_body_size    = conf.max_body_size;
}

void ServerConnection::start () {
    if (idle_timeout) {
        idle_timer = new Timer(server->loop());
        idle_timer->event.add([this](auto&){
            assert(!requests.size());
            this->close({}, true);
        });
        idle_timer->once(idle_timeout);
    }
}

protocol::http::RequestSP ServerConnection::new_request () {
    return factory ? factory->new_request(this) : ServerRequestSP(new ServerRequest(this));
}

void ServerConnection::on_read (string& buf, const ErrorCode& err) {
    ServerSP holdsrv = server; // protect against user loosing all server refs in one of the callbacks
    ServerConnectionSP hold = this; // finish_request may remove this connection
    panda_log_debug("recv: \n" << buf);

    if (err) {
        if (idle_timer) idle_timer->stop();
        panda_log_notice("read error: " << err);
        if (!requests.size() || requests.back()->is_done()) requests.emplace_back(static_pointer_cast<ServerRequest>(new_request()));
        requests.back()->_is_done = true;
        return request_error(requests.back(), err);
    }

    while (buf) {
        if (idle_timer) idle_timer->stop(); // we must stop timer every request because user might have responded to previous and timer might have been activated again
        auto result = parser.parse_shift(buf);

        auto req = static_pointer_cast<ServerRequest>(result.request);
        if (!requests.size() || requests.back() != req) requests.emplace_back(req);
        req->_is_done = result.state >= State::done;

        if (result.error) {
            panda_log_notice("parser error: " << result.error);
            return request_error(req, result.error);
        }

        if (result.state <= State::headers) {
            panda_log_debug("got part, headers not finished");
            return;
        }

        panda_log_debug("got part, body finished = " << req->is_done());

        if (!req->_routed) {
            req->_routed = true;
            req->_server = server; // hold server until request completed
            server->route_event(req);
        }

        if (req->_partial) {
            req->partial_event(req, {});
        }
        else if (result.state == State::done) {
            req->receive_event(req);
            server->request_event(req);
        }

        if (result.state == State::done) {
            // if request is non-KA or non-KA response is already started, stop receiving any further requests
            if (req->_finish_on_receive) finish_request();
            else if (closing || !req->keep_alive()) {
                stream->read_ignore();
                break; // skip parsing possible rest of the buffer
            }
        }
    }
}

void ServerConnection::respond (const ServerRequestSP& req, const ServerResponseSP& res) {
    ServerConnectionSP hold = this; (void)hold;
    assert(req->_connection == this);
    panda_log_info("respond " << req << "," << res << "," << requests.front());
    if (req->_response) throw HttpError("double response for request given");
    req->_response = res;
    res->_request = req;

    ++requests_processed;
    if (max_keepalive_requests && requests_processed >= max_keepalive_requests && requests.size() == 1) {
        graceful_stop();
    }

    if (stopping) res->keep_alive(false); // force connection close, we are gracefully stopping
    if (!res->chunked || res->body.length()) res->_completed = true;
    if (requests.front() == req) write_next_response();
}

void ServerConnection::write_next_response () {
    auto req = requests.front();
    auto res = req->_response;

    if (!res->code) res->code = 200;
    if (!res->headers.has("Date")) res->headers.date(server->date_header_now());

    decltype(res->body.parts) tmp_chunks;
    if (res->chunked && !res->_completed && res->body.length()) {
        tmp_chunks = std::move(res->body.parts);
        res->body.parts.clear();
    }

    panda_log_debug("sending <<\n" << res->to_string(req));

    auto v = res->to_vector(req);
    stream->write(v.begin(), v.end());
    server->write_request_queued();

    if (!res->keep_alive() || !req->keep_alive()) {
        closing = true;

        // stop accepting further requests if this request is fully received.
        // if not, we'll continue receiving current request until it's done (read_ignore() will be called later by on_read() because closing==true)
        if (req->is_done()) stream->read_ignore();

        if (requests.size() > 1) { // drop all pipelined requests
            requests.pop_front();
            drop_requests(errc::pipeline_canceled);
            requests.push_front(req);
        }
    }

    if (!res->_completed) {
        if (tmp_chunks.size()) {
            for (auto& chunk : tmp_chunks) {
                auto v = res->make_chunk(chunk);
                stream->write(v.begin(), v.end());
                server->write_request_queued();
            }
        }
        return;
    }

    finish_request();
}

void ServerConnection::send_continue (const ServerRequestSP& req) {
    assert(requests.size());
    if (requests.front() != req) return; // do not send 100 in pipeline
    if (!req->expects_continue() || req->http_version == 10) return; // client doesn't expect 100
    if (req->_response) throw HttpError("100-continue can only be sent before response");

    stream->write("HTTP/1.1 100 Continue\r\n\r\n");
    server->write_request_queued();
}

void ServerConnection::send_chunk (const ServerResponseSP& res, const string& chunk) {
    assert(requests.size());
    if (!chunk) return;

    if (requests.front()->_response == res) {
        auto v = res->make_chunk(chunk);
        stream->write(v.begin(), v.end());
        server->write_request_queued();
        return;
    }

    res->body.parts.push_back(chunk);
}

void ServerConnection::send_final_chunk (const ServerResponseSP& res, const string& chunk) {
    assert(requests.size());
    res->_completed = true;
    if (requests.front()->_response != res) return;

    auto v = res->final_chunk(chunk);
    stream->write(v.begin(), v.end());
    server->write_request_queued();
    finish_request();
}

void ServerConnection::finish_request () {
    ServerSP holdsrv = server; (void)holdsrv; // cleanup_request() may release last server ref

    auto req = requests.front();
    assert(req->_response && req->_response->_completed);
    if (!req->is_done()) {
        // response is complete but request is not yet fully received -> wait until end of request (on_read() will call finish_request() again)
        req->_finish_on_receive = true;
        return;
    }

    cleanup_request();

    if (closing || stopping) {
        // the only way we can get here with closing=false and stopping=true is when chunked response started before graceful stop
        assert(!requests.size());
        close({}, true);
        return;
    }

    if (requests.size()) {
        if (requests.front()->_response) write_next_response();
    }
    else if (idle_timer) {
        assert(!idle_timer->active());
        idle_timer->once(idle_timeout);
    }
}

void ServerConnection::cleanup_request () {
    auto req = requests.front();
    req->_connection = nullptr;
    req->_server = nullptr; // release server
    requests.pop_front();
    req->finish_event(req);
}

void ServerConnection::on_write (const ErrorCode& err, const WriteRequestSP&) {
    server->write_request_completed();
    if (!err) return;
    panda_log_notice("write error: " << err);
    close(err, false);
}

void ServerConnection::on_eof () {
    panda_log_info("eof");
    close(make_error_code(std::errc::connection_reset), true);
}

void ServerConnection::drop_requests (const ErrorCode& err) {
    while (requests.size()) {
        auto req = requests.front();
        // remove request from pool first, because no one listen for responses,
        // we need request/response objects to completely ignore any calls to respond(), send_chunk(), end_chunk()
        cleanup_request();
        if (!req->is_done()) {
            if (req->_partial) req->partial_event(req, err);
            else               server->error_event(req, err);
        } else {
            if (req->_response && req->_response->_completed) {} // nothing to do. user already processed and forgot this request
            else req->drop_event(req, err);
        }
    }
}

void ServerConnection::close (const ErrorCode& err, bool soft) {
    panda_log_debug("connection close: soft: " << soft << " " << err);
    ServerConnectionSP hold = this; (void)hold;
    ServerSP hold_srv = server; (void)hold_srv;

    stream->event_listener(nullptr);

    if (idle_timer) {
        idle_timer->stop();
        idle_timer = nullptr;
    }

    soft ? stream->disconnect() : stream->reset();
    drop_requests(err);

    server->remove(this);
}

void ServerConnection::graceful_stop () {
    // immediately soft-close connection if we are idle
    if (!requests.size()) {
        close(errc::server_stopping, true);
        return;
    }

    // otherwise close it after answering current request
    stopping = true;
}

ServerResponseSP ServerConnection::default_error_response (int code) {
    ServerResponseSP res = new ServerResponse(code);
    res->keep_alive(false);
    res->headers.date(server->date_header_now());

    string body(600);
    body +=
        "<html>\n"
        "<head><title>";
    body += res->full_message();
    body +=
        "</title></head>\n"
        "<body bgcolor=\"white\">\n"
        "<center><h1>";
    body += res->full_message();
    body +=
        "</h1></center>\n"
        "<hr><center>UniEvent-HTTP</center>\n"
        "</body>\n"
        "</html>\n";
    for (int i = 0; i < 6; ++i) body += "<!-- a padding to disable MSIE and Chrome friendly error page -->\n";

    res->body = body;

    return res;
}

void ServerConnection::request_error (const ServerRequestSP& req, const ErrorCode& err) {
    auto hold = req; // in case of respond in _event that remove req from requests
    stream->read_ignore();
    if (req->_partial) req->partial_event(req, err);
    else               server->error_event(req, err);

    auto res = req->_response;
    if (!res) respond(req, default_error_response(400));
    else if (res->keep_alive()) res->headers.set("Connection", "close");
}

}}}
