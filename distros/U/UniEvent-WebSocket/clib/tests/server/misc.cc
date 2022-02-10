#include "../lib/test.h"
#include "panda/protocol/websocket/inc.h"
#include "panda/unievent/websocket/ServerConnection.h"

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