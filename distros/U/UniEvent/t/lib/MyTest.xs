#include <xs/unievent.h>
#include "test.h"

MODULE = MyTest                PACKAGE = MyTest
PROTOTYPES: DISABLE

int create_socket (int domain, int type, int protocol) {
    auto sock = unievent::socket(domain, type, protocol).value();
    RETVAL = sock2fd(sock);
}

void connect_socket (int fd, net::SockAddr sa) {
    unievent::connect(fd2sock(fd), sa);
}

void close_socket (int fd) {
    unievent::close(fd2sock(fd));
}

void core_dump () { abort(); }

bool variate_ssl (bool val = false) {
    if (items) variation.ssl = val;
    RETVAL = variation.ssl;
}

bool variate_buf (bool val = false) {
    if (items) variation.buf = val;
    RETVAL = variation.buf;
}

void set_loop_callback_with_mortal (LoopSP loop, xs::Sub cb) {
    loop->delay([=]{
        auto param = newSV(0);
        newSVrv(param, "MyMortal");
        sv_2mortal(param);
        cb.call(param);
    });
}

void _benchmark_simple_resolver () { 
    LoopSP loop(new Loop);
    ResolverSP resolver(new Resolver(loop));
    
    for (auto i = 0; i < 1000; i++) {
        bool called = false;
        resolver->resolve()->node("localhost")->use_cache(false)->on_resolve([&](auto...) {
            called = true;
        })->run();
    }
    
    loop->run();
}

void _benchmark_cached_resolver () { 
    LoopSP loop(new Loop);
    ResolverSP resolver(new Resolver(loop));
   
    // put it into cache first 
    bool called = false;                                                          
    resolver->resolve("localhost", [&](auto...) {
        called = true;
    });
    
    // will resolve and cache here, loop will exit as there are no pending requests
    loop->run();

    // resolve gets address from cache 
    for (auto i = 0; i < 99999; i++) {
        bool called = false;                                                          
        resolver->resolve("localhost", [&](auto...) {
            called = true;
        });
    }
    
    loop->run();
}

void _benchmark_timer_start_stop (LoopSP loop, int tmt, int cnt) {
    TimerSP timer(new Timer(loop));
    for (int i = 0; i < cnt; ++i) {
        timer->start(tmt);
        timer->stop();
    }
}

void _benchmark_loop_update_time (int cnt) {
    LoopSP loop(new Loop);
    for (int i = 0; i < cnt; ++i) loop->update_time();
}

void _bench_delay_add_rm (int cnt) {
    auto loop = Loop::default_loop();
    for (int i = 0; i < cnt; ++i) {
        auto ret = loop->delay([]{});
        loop->cancel_delay(ret);
    }
}

void _bench_loop_iter (int cnt) {
    auto l = Loop::default_loop();
    for (int i = 0; i < cnt; ++i) l->run_nowait();
}

INCLUDE: BenchTcp.xsi