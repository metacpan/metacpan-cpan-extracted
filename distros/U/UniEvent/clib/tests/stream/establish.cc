#include "../lib/test.h"
#include "panda/error.h"
#include "panda/unievent/Stream.h"
#include "panda/unievent/forward.h"

TEST_PREFIX("stream-establish: ", "[stream-establish]");

struct Elst : IStreamListener {
    Stream::connection_fn scb;
    Stream::connect_fn    ccb;
    Elst(Stream::connection_fn scb) : scb(scb) {}
    Elst(Stream::connect_fn ccb) : ccb(ccb) {}
    void on_establish(const StreamSP& server, const StreamSP& client, const ErrorCode& err) override { scb(server, client, err); }
    void on_establish(const StreamSP& stream, const ErrorCode& err, const ConnectRequestSP& req) override { ccb(stream, err, req); }
};

struct Efilter : StreamFilter {
    AsyncTest& test;
    Efilter (AsyncTest& t, Stream* stream) : StreamFilter(stream, nullptr, 0), test(t) {}
    
    void handle_connection (const StreamSP& stream, const ErrorCode& err, const AcceptRequestSP& req) override {
        test.happens("filter-connection");
        NextFilter::handle_connection(stream, err, req);
    }
    
    void handle_connect (const ErrorCode& err, const ConnectRequestSP& req) override {
        test.happens("filter-connect");
        NextFilter::handle_connect(err, req);
    }
};

TEST("server establish") {
    AsyncTest test(1000, {"establish", "filter-connection", "cli-connection", "connection"});
    
    TcpSP server = new Tcp(test.loop);
    Elst lst([&](const StreamSP&, const StreamSP& cli, const ErrorCode& err){
        CHECK(!err);
        test.happens("establish");
        cli->connection_event.add([&](auto& srv, auto&, auto& err){
            CHECK(srv == server);
            CHECK(!err);
            test.happens("cli-connection");
        });
    });
    server->event_listener(&lst);
    server->add_filter(new Efilter(test, server));
    server->connection_event.add([&](auto...) {
        test.happens("connection");
        test.loop->stop();
    });
    server->bind("localhost", 0);
    server->listen();
    
    TcpSP client = new Tcp(test.loop);
    client->connect(server->sockaddr().value());
    test.run();
}

TEST("client establish") {
    AsyncTest test(1000, {"establish", "filter-connect", "connect"});
    
    TcpSP server = new Tcp(test.loop);
    StreamSP sconn;
    server->connection_event.add([&](auto, auto cli, auto) { sconn = cli; });
    server->bind("localhost", 0);
    server->listen();
    
    Elst lst([&](const StreamSP&, const ErrorCode& err, const ConnectRequestSP&){
        CHECK(!err);
        test.happens("establish");
    });
    TcpSP client = new Tcp(test.loop);
    client->event_listener(&lst);
    client->add_filter(new Efilter(test, client));
    client->connect_event.add([&](auto...) {
        test.happens("connect");
        test.loop->stop();
    });
    client->connect(server->sockaddr().value());
    test.run();
}

TEST("establish error") {
    AsyncTest test(1000, 2);
    
    TcpSP client = new Tcp(test.loop);
    ErrorCode err;
    Elst lst([&](const StreamSP&, const ErrorCode& _err, const ConnectRequestSP&){
        err = _err;
        CHECK(err);
        test.happens();
    });
    client->event_listener(&lst);
    client->connect_event.add([&](auto, auto& _err, auto) {
        CHECK(_err == err);
        test.happens();
        test.loop->stop();
    });
    client->connect(test.get_refused_addr());
    test.run();
}