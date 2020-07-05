#pragma once
#include <mutex>
#include <chrono>
#include <thread>
#include <catch.hpp>
#include <panda/unievent.h>
#include <panda/unievent/test/AsyncTest.h>

using namespace panda;
using namespace panda::unievent;
using namespace panda::unievent::test;
using ms  = std::chrono::milliseconds;
using sec = std::chrono::seconds;
using panda::net::SockAddr;

constexpr std::chrono::milliseconds operator""_ms (unsigned long long val) { return std::chrono::milliseconds(val); }
constexpr std::chrono::seconds      operator""_s  (unsigned long long val) { return std::chrono::seconds(val); }

struct Variation {
    bool ssl;
    bool buf;
};

extern Variation variation;

#if !defined(__NetBSD__)
struct TimeGuard {
    std::thread t;
    std::timed_mutex m;

    TimeGuard (const std::chrono::milliseconds& tmt) {
        m.lock();
        t = std::thread([=]{
            if (!m.try_lock_for(tmt)) throw std::logic_error("Test timeouted");
        });
    }

    ~TimeGuard () {
        m.unlock();
        t.join();
    }
};
#else
struct TimeGuard {
    TimeGuard (const std::chrono::milliseconds&) {}
};
#endif

template <class T>
void time_guard (const std::chrono::milliseconds& tmt, T fn) {
    TimeGuard a(tmt);
    fn();
}

struct TcpPair {
    TcpSP server;
    TcpSP client;
};

struct TcpP2P {
    TcpSP server;
    TcpSP sconn;
    TcpSP client;
};

TcpSP  make_basic_server (const LoopSP& loop, const SockAddr& sa = SockAddr::Inet4("127.0.0.1", 0));
TcpSP  make_ssl_server   (const LoopSP& loop, const SockAddr& sa = SockAddr::Inet4("127.0.0.1", 0));
TcpSP  make_server       (const LoopSP& loop, const SockAddr& sa = SockAddr::Inet4("127.0.0.1", 0));
TcpSP  make_client       (const LoopSP& loop);
TcpP2P make_tcp_pair     (const LoopSP& loop, const SockAddr& sa = SockAddr::Inet4("127.0.0.1", 0));
TcpP2P make_p2p          (const LoopSP& loop, const SockAddr& sa = SockAddr::Inet4("127.0.0.1", 0));

