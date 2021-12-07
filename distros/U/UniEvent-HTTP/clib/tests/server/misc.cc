#include "../lib/test.h"

#define TEST(name) TEST_CASE("server-misc: " name, "[server-misc]" VSSL)

TEST("using socket in config location") {
    LoopSP tmp_loop = new Loop();
    TcpSP tcp = new Tcp(tmp_loop);
    tcp->bind("localhost", 0);

    AsyncTest test(1000, 1);
    Server::Config cfg;
    Server::Location loc;
    loc.sock = tcp->socket().value();
    cfg.locations.push_back(loc);
    ServerPair p(test.loop, cfg);

    p.server->request_event.add([&](auto req) {
        test.happens();
        CHECK(req->headers.host() == "epta.ru");
        test.loop->stop();
    });

    p.conn->write(
        "GET / HTTP/1.1\r\n"
        "Host: epta.ru\r\n"
        "\r\n"
    );

    test.run();
}

TEST("unix-socket / named pipe") {
    AsyncTest test(1000, 1);
    Server::Config cfg;
    Server::Location loc;
    loc.path = "tests/testsock";
    cfg.locations.push_back(loc);

    auto server = make_server(test.loop, cfg);
    PipeSP conn = new Pipe(test.loop);
    if (secure) {  conn->use_ssl( TClient::get_context("01-alice")); }
    conn->connect_event.add([](auto& conn, auto& err, auto){
        if (err) {
            printf("server pair connect error: %s\n", err.what().c_str());
            throw err;
        }
        conn->loop()->stop();
    });
    conn->connect(loc.path);
    test.loop->run();

    server->request_event.add([&](auto req) {
        test.happens();
        CHECK(req->headers.host() == "epta.ru");
        test.loop->stop();
    });

    conn->write(
        "GET / HTTP/1.1\r\n"
        "Host: epta.ru\r\n"
        "\r\n"
    );

    test.run();
}

#ifndef _WIN32
TEST("unix-socket in config.location.sock") {
    AsyncTest test(1000, 1);
    Server::Config cfg;
    Server::Location loc;
    unievent::Fs::unlink("tests/testsock").nevermind();
    loc.sock = panda::unievent::socket(AF_UNIX, SOCK_STREAM, 0).value();
    panda::unievent::bind(loc.sock.value(), net::SockAddr::Unix("tests/testsock"));
    cfg.locations.push_back(loc);

    auto server = make_server(test.loop, cfg);
    PipeSP conn = new Pipe(test.loop);
    if (secure) {  conn->use_ssl( TClient::get_context("01-alice")); }
    conn->connect_event.add([](auto& conn, auto& err, auto){
        if (err) {
            printf("server pair connect error: %s\n", err.what().c_str());
            throw err;
        }
        conn->loop()->stop();
    });
    conn->connect("tests/testsock");
    test.loop->run();

    server->request_event.add([&](auto req) {
        test.happens();
        CHECK(req->headers.host() == "epta.ru");
        test.loop->stop();
    });

    conn->write(
        "GET / HTTP/1.1\r\n"
        "Host: epta.ru\r\n"
        "\r\n"
    );

    test.run();

    unievent::Fs::unlink("tests/testsock").nevermind();
}
#endif
