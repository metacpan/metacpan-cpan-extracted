#include "AsyncTest.h"
#include <uv.h> // for getaddrinfo
#include <sstream>
#include <iostream>
#include <unistd.h>
#include <panda/log.h>

namespace panda { namespace unievent { namespace test {

using panda::net::SockAddr;

static int refused_port = 10000;

SockAddr AsyncTest::get_refused_addr () {
    ++refused_port;
    if (refused_port > 40000) refused_port = 10000;
    #ifdef _WIN32
        return SockAddr::Inet4("0.1.1.1", refused_port);
    #elif defined(__APPLE__) || defined(__NetBSD__)
        return SockAddr::Inet4("0.0.0.0", refused_port);
    #else
        static TcpSP rs;
        if (!rs) {
            rs = new Tcp();
            rs->bind("127.0.0.1", 0);
        }
        return rs->sockaddr();
    #endif
}

SockAddr AsyncTest::get_blackhole_addr () {
    static SockAddr ret;
    if (!ret) {
        addrinfo* res;
        int syserr = getaddrinfo("google.com", "81", NULL, &res);
        if (syserr) throw std::system_error(std::make_error_code(((std::errc)syserr)));
        ret = SockAddr(res->ai_addr, sizeof(*res->ai_addr));
        freeaddrinfo(res);
    }
    return ret;
}

AsyncTest::AsyncTest (uint64_t timeout, const std::vector<string>& expected, const LoopSP& loop)
    : loop(loop ? loop : LoopSP(new Loop()))
    , expected(expected)
    , timer(create_timeout(timeout))
{}

AsyncTest::AsyncTest (uint64_t timeout, unsigned count, const LoopSP& loop) : AsyncTest(timeout, std::vector<string>(), loop) {
    set_expected(count);
}

AsyncTest::~AsyncTest() noexcept(false) {
    if (std::uncaught_exception()) {
        return;
    }
    loop->run_nowait();
    if (!happened_as_expected()) {
        throw Error("Test exits in bad state", *this);
    }
}

void AsyncTest::set_expected (unsigned count) {
    expected.clear();
    for (unsigned i = 0; i < count; ++i) expected.push_back("<event>");
}

void AsyncTest::set_expected (const std::vector<string>& v) {
    expected = v;
}

void AsyncTest::run        () { loop->run(); }
void AsyncTest::run_once   () { loop->run_once(); }
void AsyncTest::run_nowait () { loop->run_nowait(); }

void AsyncTest::happens (string event) {
    if (event) {
        happened.push_back(event);
    }
}

std::string AsyncTest::generate_report() {
    std::stringstream out;

    for (size_t i = 0; i < std::max(expected.size(), happened.size()); ++i) {
        if (i >= expected.size()) {
            out << "\t\"" << happened[i] << "\" was not expected" << std::endl;
            continue;
        }
        if (i >= happened.size()) {
            out << "\t\"" << expected[i] << "\" has not happened" << std::endl;
            continue;
        }
        if (happened[i] != expected[i]) {
            out << "\t" << "wrong event " << happened[i] << ", " << expected[i] << " expected at pos " << i << std::endl;
            break;
        }
    }
    if (happened_as_expected()) {
        out << "OK" << std::endl;
    } else {
        out << "Expected: ";
        for (auto& e : expected) {
            out << "\"" << e << "\",";
        }
        out << std::endl << "Happened: ";
        for (auto& h : happened) {
            out << "\"" << h << "\",";
        }
        out << std::endl;
    }
    return out.str();
}

bool AsyncTest::happened_as_expected() {
    if (happened.size() != expected.size()) {
        return false;
    }
    for (size_t i = 0; i < happened.size(); ++i) {
        if (happened[i] != expected[i]) {
            return false;
        }
    }
    return true;
}

sp<Timer> AsyncTest::create_timeout(uint64_t timeout) {
    auto ret = timer_once(timeout, loop, [&]() {
        throw Error("AsyncTest timeout", *this);
    });
    ret->weak(true);
    return ret;
}

AsyncTest::Error::Error(std::string msg, AsyncTest& test)
    : std::runtime_error(msg + "\nAsyncTest report:\n" + test.generate_report())
{}

}}}
