#include "lib/test.h"
#include "panda/log/log.h"
#include "panda/unievent/forward.h"
#include "panda/unievent/log.h"
#include "uv.h"
#include <catch2/generators/catch_generators.hpp>


TEST_PREFIX("regression: ", "[regression]");

//TODO: this test should have been failing before fix, but it did not
//TODO: find a way to reproduce SRV-1273 from UniEvent
TEST("UniEvent SRV-1273") {
    variation = GENERATE(values(ssl_vars));

    AsyncTest test(1000, {});
    SockAddr addr = test.get_refused_addr();
    std::vector<TcpSP> clients;
    size_t counter = 0;

    auto client_timer = Timer::create(30, [&](TimerSP) {
        if (++counter == 10) {
            test.loop->stop();
        }
        TcpSP client = new Tcp(test.loop);
        client->connect_event.add([](auto s, auto& err, auto){
            REQUIRE(err);
            s->reset();
        });

        client->connect(addr.ip(), addr.port());
        for (size_t i = 0; i < 2; ++i) {
            client->write("123", ([](auto s, auto& err, auto){
                REQUIRE(err);
                s->reset();
            }));
        }
        clients.push_back(client);
    }, test.loop);

    test.loop->run();
    clients.clear();
    REQUIRE(counter == 10);
}

TEST("MEIACORE-734 ssl server backref") {
    AsyncTest test(500, {"connect"});
    TcpSP server = make_ssl_server(test.loop);
    TcpSP sconn;

    server->connection_factory = [&](auto) {
        sconn = new Tcp(test.loop);
        return sconn;
    };

    server->connection_event.add([&](auto...) {
        FAIL("should not be called");
    });

    TcpSP client = new Tcp(test.loop);
    client->connect(server->sockaddr().value());
    test.await(client->connect_event, "connect");

    server = nullptr;
    test.loop->run_nowait();
    client->reset();
    client = nullptr;

    test.run();
}

TEST("MEIACORE-751 callback recursion") {
    AsyncTest test(10000, {});
    SockAddr addr = test.get_refused_addr();

    TcpSP client = new Tcp(test.loop);

    size_t counter = 0;
    client->connect_event.add([&](auto...) {
        if (++counter < 5) {
            client->connect()->to(addr.ip(), addr.port())->run();
            client->write("123");
        } else {
            test.loop->stop();
        }
    });

    client->connect()->to(addr.ip(), addr.port())->run();
    client->write("123");

    test.loop->run();
    REQUIRE(counter == 5);
}


#ifndef _WIN32

#include <unistd.h>
#include <csignal>

TEST("MEIACORE-1839 signal remove") {
    LoopSP main_loop = new Loop();
    SignalSP s = new Signal(main_loop);

    LoopSP loop = new Loop();
    SignalSP child_sig = new Signal(loop);
    child_sig->start(SIGHUP, [&](auto, int) {
        panda_log_debug(unievent::panda_log_module, "child caught");
    });

    pid_t child_pid;
    TimerSP timer;

    auto timeout = [&](auto) {
        if (child_pid) {
            kill(child_pid, SIGKILL);
        }
        FAIL("timeout");
    };

    s->start(SIGHUP, [&](auto, int) {
        child_pid = fork();
        if (child_pid) {
            timer = Timer::create_once(5000, timeout, main_loop);
            s = new Signal(main_loop);
            s->start(SIGCHLD, [&](auto, int) {
                s.reset();
                timer.reset();
            });
        } else {
            s.reset();
        }
        child_sig.reset();
        loop->run();
    });

    auto pid = ::getpid();
    kill(pid, SIGHUP);
    main_loop->run();

    if (!child_pid) { // child
        exit(0); // to prevent any test output from child process
    }
}

#endif
