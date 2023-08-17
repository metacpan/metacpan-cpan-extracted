#include "../lib/test.h"
#include "panda/protocol/websocket/inc.h"
#include "panda/unievent/Loop.h"
#include "panda/unievent/SslContext.h"
#include "panda/unievent/websocket/Client.h"
#include "panda/unievent/websocket/Connection.h"
#include "panda/unievent/websocket/Server.h"
#include "panda/unievent/websocket/ServerConnection.h"
#include <iostream>

TEST_PREFIX("server-misc: ", "[server-misc]" VSSL);

TEST("using socket in config location") {
    LoopSP tmp_loop = new Loop();
    TcpSP tcp = new Tcp(tmp_loop);
    tcp->bind("localhost", 0);

    AsyncTest test(1000, 1);
    Server::Config cfg;
    cfg.locations.push_back(Location().set_sock(tcp->socket().value()));
    ServerPair p(test.loop, cfg);

    p.sconn->message_event.add([&](auto, auto& msg){
        test.happens();
        CHECK_PAYLOAD(msg, "hello world");
        test.loop->stop();
    });

    p.send("hello world");

    test.run();
}

TEST("unix-socket / named pipe") {
    AsyncTest test(1000, 1);
    Server::Config cfg;
    cfg.locations.push_back(Location().set_path("tests/testsock1"));

    ServerPair p(test.loop, cfg, true);
    p.sconn->message_event.add([&](auto, auto& msg){
        test.happens();
        CHECK_PAYLOAD(msg, "hello world");
        test.loop->stop();
    });

    p.send("hello world");
    test.run();
}

#ifndef _WIN32
TEST("unix-socket in config.location.sock") {
    AsyncTest test(1000, 1);
    unievent::Fs::unlink("tests/testsock2").nevermind();
    auto sock = unievent::socket(AF_UNIX, SOCK_STREAM, 0).value();
    unievent::bind(sock, net::SockAddr::Unix("tests/testsock2"));
    Server::Config cfg;
    cfg.locations.push_back(Location().set_sock(sock));

    ServerPair p(test.loop, cfg, true);
    p.sconn->message_event.add([&](auto, auto& msg){
        test.happens();
        CHECK_PAYLOAD(msg, "hello world");
        test.loop->stop();
    });

    p.send("hello world");
    test.run();
    unievent::Fs::unlink("tests/testsock2").nevermind();
}
#endif

TEST("running with no listeners") {
    AsyncTest test(1000);
    Server::Config cfg;
    ServerSP server = new Server(test.loop);
    server->configure(cfg);
    test.run();
    SUCCEED("loop is not busy");
}

TEST_CASE("ws synopsis", "[.]") {
    // Client
    ClientSP client = new Client();
    client->connect("ws://myserver.com:12345");
    client->connect_event.add([](ClientSP client, ConnectResponseSP connect_response) {
        if (connect_response->error()) { /*...*/ }
        client->send_text("hello");
    });
    client->message_event.add([](ConnectionSP client, MessageSP message){
        for (string s : message->payload) {
            std::cout << s;
        }
        client->close(CloseCode::DONE);
    });
    client->peer_close_event.add([](ConnectionSP /*client*/, MessageSP message) {
        std::cout << message->close_code();
        std::cout << message->close_message();
    });

    unievent::Loop::default_loop()->run();

    // Server
    Server::Config conf;
    Location ws;
    ws.host = "*";
    ws.port = 80;
    ws.reuse_port = 1;
    ws.backlog = 1024;
    conf.locations.push_back(ws);

    Location wss = ws;
    wss.port = 443;
    wss.set_ssl_ctx(SslContext()); // set actual context with keys
    conf.locations.push_back(wss);

    conf.max_frame_size = 1000;
    conf.max_message_size = 100'000;
    conf.deflate->compression_level = 3;
    conf.deflate->compression_threshold = 1000;

    ServerSP server = new Server();
    server->configure(conf);

    server->connection_event.add([](ServerSP /*server*/, ServerConnectionSP client, ConnectRequestSP) {
        client->message_event.add([](ConnectionSP /*client*/, MessageSP message) {
            for (string s : message->payload) {
                std::cout << s;
            }
        });
        client->peer_close_event.add([](ConnectionSP /*client*/, MessageSP message) {
            std::cout << message->close_code();
            std::cout << message->close_message();
        });
        client->send_text("hello from server");
    });

    server->run();
    unievent::Loop::default_loop()->run();
}