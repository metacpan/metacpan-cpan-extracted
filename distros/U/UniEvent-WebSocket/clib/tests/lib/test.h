#pragma once
#include "panda/protocol/websocket/ClientParser.h"
#include "panda/protocol/websocket/ConnectRequest.h"
#include "panda/protocol/websocket/inc.h"
#include "panda/unievent/Loop.h"
#include "panda/unievent/SslContext.h"
#include "panda/unievent/Timer.h"
#include "panda/unievent/forward.h"
#include "panda/unievent/websocket/ServerConnection.h"
#include <panda/log.h>
#include <panda/test/catch.h>
#include <panda/unievent/websocket.h>
#include <panda/unievent/test/AsyncTest.h>
// // #include <memory>
// // #include <functional>
// #include <catch2/generators/catch_generators.hpp>
// #include <catch2/matchers/catch_matchers_string.hpp>

using namespace panda;
// using namespace panda::unievent;
using namespace panda::unievent::test;
using namespace panda::unievent::websocket;
using Location = unievent::http::Server::Location;
using unievent::SslContext;
using unievent::Loop;
using unievent::LoopSP;
using unievent::StreamSP;
using unievent::Pipe;
using unievent::PipeSP;
using unievent::Tcp;
using unievent::TcpSP;


#define VSSL "[v-ssl]"

#define CHECK_PAYLOAD(msg, str) do {        \
    string full;                            \
    for (auto& s : msg->payload) full += s; \
    CHECK(full == str);                     \
} while (0)

extern bool secure;

struct TServer : Server {
    static int dcnt;

    using Server::Server;

    //string location    () const;
    //NetLoc netloc      () const;
    //string uri         () const;

    static SslContext get_context(string cert_name = "ca");

    ~TServer () { ++dcnt; }
};
using TServerSP = iptr<TServer>;


struct TClient : Client {
    static int dcnt;
    net::SockAddr sa;

    using Client::Client;

    //void request (const RequestSP&);

    // ResponseSP get_response (const RequestSP& req);
    // ResponseSP get_response (const string& uri, Headers&& = {}, Body&& = {}, bool chunked = false);

    // ErrorCode get_error (const RequestSP& req);
    // ErrorCode get_error (const string& uri, Headers&& = {}, Body&& = {}, bool chunked = false);

    static SslContext get_context(string cert_name, const string& ca_name = "ca");

    ~TClient () { ++dcnt; }

    // friend struct TPool;
};
using TClientSP = iptr<TClient>;


struct ServerPair {
    using Parser    = panda::protocol::websocket::ClientParser;
    using Responses = std::deque<string>;
    //using RawResponses = std::deque<string>;

    TServerSP          server;
    StreamSP           conn;
    ServerConnectionSP sconn;
    //RawRequestSP source_request;

    ServerPair(const LoopSP&, Server::Config = {}, bool unixsock = false);

    void enable_echo();
    void autorespond(const string&);

    void send (const string& str, Opcode = Opcode::TEXT);

    //RawResponseSP get_response ();
    //RawResponseSP get_response (const string& s) { conn->write(s); return get_response(); }
    //int64_t       wait_eof     (int tmt = 0);

private:
    Parser    parser;
    bool      autores = false;
    Responses autoresponse_queue;
    //RawResponses response_queue;
    //int64_t      eof = 0;
};

TServerSP make_server (const LoopSP&, Server::Config = {});
















// string active_scheme();

// static auto fail_cb = [](auto...){ FAIL(); };

// int64_t get_time     ();
// void    time_mark    ();
// int64_t time_elapsed ();

// ResponseSP              await_response (const RequestSP&, const LoopSP&);
// std::vector<ResponseSP> await_responses(const std::vector<RequestSP>&, const LoopSP&);
// ResponseSP              await_any      (const std::vector<RequestSP>&, const LoopSP&);





// struct TPool : Pool {
//     using Pool::Pool;

//     TClientSP request (const RequestSP& req);

// protected:
//     ClientSP new_client () override { return new TClient(this); }
// };
// using TPoolSP = iptr<TPool>;

// struct TProxy {
//     TcpSP server;
//     URISP url;
// };

// TProxy new_proxy(const LoopSP&, const net::SockAddr& sa = net::SockAddr::Inet4("127.0.0.1", 0));

// struct ClientPair {
//     TServerSP server;
//     TClientSP client;
//     TProxy proxy;

//     ClientPair (const LoopSP&, bool with_proxy = false);
// };





// TServerSP make_ssl_server (const LoopSP&);
