#pragma once
#include "msg.h"
#include "error.h"
#include "Response.h"
#include "Form.h"
#include <panda/unievent/Tcp.h>
#include <panda/unievent/Timer.h>
#include <panda/unievent/AddrInfo.h>
#include <panda/CallbackDispatcher.h>

namespace panda { namespace unievent { namespace http {

struct Client;          using ClientSP  = iptr<Client>;
struct Request;         using RequestSP = iptr<Request>;
struct RedirectContext; using RedirectContextSP = iptr<RedirectContext>;

using panda::unievent::AddrInfoHints;

extern bool default_ssl_verify;

struct NetLoc {
    string     host;
    uint16_t   port    = 0;
    SslContext ssl_ctx = nullptr;
    URISP      proxy;
    bool       ssl_check_cert = true;


    bool operator== (const NetLoc& other) const {
        return host == other.host && port == other.port && ssl_ctx == other.ssl_ctx && proxy == other.proxy && ssl_check_cert == other.ssl_check_cert;
    }
    bool operator!= (const NetLoc& other) const { return !operator==(other); }
};
std::ostream& operator<< (std::ostream& os, const NetLoc& h);

struct Request : protocol::http::Request {
    struct Builder;
    using response_fptr = void(const RequestSP&, const ResponseSP&, const ErrorCode&);
    using partial_fptr  = void(const RequestSP&, const ResponseSP&, const ErrorCode&);
    using redirect_fptr = void(const RequestSP&, const ResponseSP&, const RedirectContextSP&);
    using continue_fptr = void(const RequestSP&);
    using response_fn   = function<response_fptr>;
    using partial_fn    = function<partial_fptr>;
    using redirect_fn   = function<redirect_fptr>;
    using continue_fn   = function<continue_fptr>;
    using Form          = std::vector<FormItemSP>;

    static constexpr const uint64_t DEFAULT_TIMEOUT           = 20000; // [ms]
    static constexpr const uint16_t DEFAULT_REDIRECTION_LIMIT = 20;    // [hops]

    uint64_t                          timeout           = DEFAULT_TIMEOUT;
    bool                              follow_redirect   = true;
    bool                              tcp_nodelay       = false;
    uint16_t                          redirection_limit = DEFAULT_REDIRECTION_LIMIT;
    CallbackDispatcher<response_fptr> response_event;
    CallbackDispatcher<partial_fptr>  partial_event;
    CallbackDispatcher<redirect_fptr> redirect_event;
    CallbackDispatcher<continue_fptr> continue_event;
    SslContext                        ssl_ctx           = nullptr;
    URISP                             proxy;
    AddrInfoHints                     tcp_hints         = Tcp::defhints;
    Form                              form;
    bool                              ssl_check_cert    = default_ssl_verify;

    Request () {}

    bool transfer_completed () const { return _transfer_completed; }

    void send_chunk        (const string& chunk);
    void send_final_chunk  (const string& chunk = {});

    void cancel (const ErrorCode& = make_error_code(std::errc::operation_canceled));

protected:
    protocol::http::ResponseSP new_response () const override { return new Response(); }

private:
    friend Client; friend struct Pool;

    uint16_t _redirection_counter = 0;
    bool     _transfer_completed  = false;
    ClientSP _client; // holds client when active
    TimerSP  _timer;

    NetLoc netloc () const { return { uri->host(), uri->port(), ssl_ctx, proxy, ssl_check_cert }; }

    void check () const {
        if (!uri) throw HttpError("request must have uri");
        if (!uri->host()) throw HttpError("uri must have host");
    }
};

struct Request::Builder : protocol::http::Request::BuilderImpl<Builder, RequestSP> {
    Builder () : BuilderImpl(new Request()) {}

    Builder& response_callback (const Request::response_fn& cb) {
        _message->response_event.add(cb);
        return *this;
    }

    Builder& partial_callback (const Request::partial_fn& cb) {
        _message->partial_event.add(cb);
        return *this;
    }

    Builder& redirect_callback (const Request::redirect_fn& cb) {
        _message->redirect_event.add(cb);
        return *this;
    }

    Builder& timeout (uint64_t timeout) {
        _message->timeout = timeout;
        return *this;
    }

    Builder& follow_redirect (bool val) {
        _message->follow_redirect = val;
        return *this;
    }

    Builder& redirection_limit (uint16_t redirection_limit) {
        _message->redirection_limit = redirection_limit;
        return *this;
    }

    Builder& ssl_ctx (const SslContext& ctx) {
        _message->ssl_ctx = ctx;
        return *this;
    }

    Builder& ssl_check_cert (bool check) {
        _message->ssl_check_cert = check;
        return *this;
    }

    Builder& proxy (const URISP& proxy) {
        _message->proxy = proxy;
        return *this;
    }

    Builder& tcp_nodelay (bool val) {
        _message->tcp_nodelay = val;
        return *this;
    }

    Builder& tcp_hints (const AddrInfoHints& hints) {
        _message->tcp_hints = hints;
        return *this;
    }

    Builder& form_field (const string& name, const string& value) {
        _message->form_stream();
        _message->form.emplace_back(new FormField(name, value));
        return *this;
    }

    Builder& form_item (FormItemSP& value) {
        _message->form_stream();
        _message->form.emplace_back(value);
        return *this;
    }

    Builder& form_file (const string& name, const string& value, const string& mime_type = "application/octet-stream", const string& filename = "") {
        _message->form_stream();
        _message->form.emplace_back(new FormEmbeddedFile(name, value, mime_type, filename));
        return *this;
    }

    Builder& form_file (const string& name, Streamer::IInputSP in, const string& mime_type = "application/octet-stream", const string& filename = "") {
        _message->form_stream();
        _message->form.emplace_back(new FormFile(name, std::move(in), mime_type, filename));
        return *this;
    }

};

struct RedirectContext: Refcnt {
    URISP    uri;
    SslContext ssl_ctx;
    Request::Cookies cookies;
    protocol::http::Headers removed_headers;

    RedirectContext(const URISP& uri_, const SslContext& ssl_ctx_, const Request::Cookies& cookies_):
        uri(uri_), ssl_ctx{ssl_ctx_}, cookies{cookies_} {}
};


}}}
