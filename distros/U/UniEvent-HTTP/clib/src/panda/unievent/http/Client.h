#pragma once
#include "error.h"
#include "Request.h"
#include "Form.h"
#include <panda/unievent/Tcp.h>
#include <panda/protocol/http/ResponseParser.h>

namespace panda { namespace unievent { namespace http {

struct Pool;
struct Client;
using ClientSP = iptr<Client>;

extern const string DEFAULT_UA;

struct Client : Tcp, private ITcpSelfListener, private ITimerListener {
    Client (const LoopSP& = Loop::default_loop());

    ~Client () { assert(!_request); }

    void request (const RequestSP&);
    void cancel  (const ErrorCode& = make_error_code(std::errc::operation_canceled));

    uint64_t      last_activity_time () const { return _last_activity_time; }
    const NetLoc& last_netloc        () const { return _netloc; }

protected:
    Client (Pool*);

private:
    friend Pool; friend Request; friend IFormItem; friend FormFile;
    using ResponseParser = protocol::http::ResponseParser;

    Pool*          _pool = nullptr;
    NetLoc         _netloc;
    RequestSP      _request;
    ResponseSP     _response;
    ResponseParser _parser;
    uint64_t       _last_activity_time = 0;
    bool           _in_redirect = false;
    bool           _redirect_canceled = false;
    int32_t        _form_field = -1;

    void on_connect (const ErrorCode&, const ConnectRequestSP&) override;
    void on_write   (const ErrorCode&, const WriteRequestSP&) override;
    void on_read    (string& buf, const ErrorCode& err) override;
    void on_timer   (const TimerSP&) override;
    void on_eof     () override;

    void send_chunk       (const RequestSP&, const string&);
    void send_final_chunk (const RequestSP&, const string&);

    void drop_connection ();
    void analyze_request ();
    void finish_request  (const ErrorCode&);

    void send_form() noexcept;
    void send_chunk(const Chunk& chunk) noexcept;
    void form_file_complete(const ErrorCode& ec);
};

}}}
