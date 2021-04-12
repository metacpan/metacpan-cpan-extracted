#include "lib/test.h"

TEST_PREFIX("util: ", "[util]");

TEST("hostname") {
    auto h = hostname();
    CHECK(h);
}

TEST("get_rss") {
    auto rss = get_rss().value();
    CHECK(rss > 0);
    std::vector<int> v;
    for (int i = 0; i < 100000; ++i) v.push_back(1);
    auto new_rss = get_rss().value();
    CHECK(new_rss > rss);
}

TEST("get_free_memory") {
    auto val = get_free_memory();
    CHECK(val > 0);
}

TEST("get_total_memory") {
    auto val = get_total_memory();
    CHECK(val > get_free_memory());
}

TEST("cpu_info") {
    auto list = cpu_info().value();
    CHECK(list.size() > 0);
    for (size_t i = 0; i < list.size(); ++i) {
        auto& row = list[i];
        CHECK(row.model);
    }
}

template <size_t N>
static string phys_to_str (const char (&a)[N]) {
    string ret;
    for (size_t i = 0; i < N; ++i) {
        if (i) ret += ':';
        char part[3];
        sprintf(part, "%02X", (unsigned char)a[i]);
        ret += part;
    }
    return ret;
}

TEST("interface info") {
    auto list = interface_info().value();
    if (!list.size()) return;

    bool found_local = false;

    for (auto& row : list) {
        CHECK(row.name);
        CHECK(phys_to_str(row.phys_addr));
        CHECK(row.address);
        CHECK(row.netmask);
        if (row.is_internal) INFO("internal");
        if (row.address.ip() == "::1" || row.address.ip() == "127.0.0.1") found_local = true;
    }

    CHECK(found_local);
}

TEST_HIDDEN("get_rusage") {
    auto rusage = get_rusage().value();
    CHECK(rusage.maxrss > 0);
}

TEST("uname") {
    auto info = uname().value();
    CHECK(info.sysname);
    WARN(info.release);
    WARN(info.version);
    WARN(info.machine);
    SUCCEED();
}

TEST("socketpair") {
    AsyncTest test(1000, 2);
    auto res = socketpair();
    REQUIRE(res);
    auto fds = res.value();

    TcpSP t1 = new Tcp(test.loop);
    TcpSP t2 = new Tcp(test.loop);

    t1->open(fds.first);
    t2->open(fds.second);

    t1->write("hello");
    t2->read_event.add([&](auto...){
        test.happens();
        t2->write("world");
    });

    t1->read_event.add([&](auto...){
        test.happens();
        t1->reset();
        t2->reset();
    });

    test.run();
    SUCCEED("ok");
}

TEST("pipe pair") {
    AsyncTest test(1000, 1);
    auto res = pipe();
    REQUIRE(res);
    auto fds = res.value();

    PipeSP reader = new Pipe(test.loop);
    PipeSP writer = new Pipe(test.loop);

    reader->open(fds.first, Pipe::Mode::readable);
    writer->open(fds.second, Pipe::Mode::writable);

    writer->write("hello");
    reader->read_event.add([&](auto...){
        test.happens();
        reader->reset();
        writer->reset();
    });

    test.run();
    SUCCEED("ok");
}

TEST("random") {
    size_t blocks = 5;
    size_t size   = 32;
    auto ret = get_random(blocks*size);
    REQUIRE((bool)ret);
    auto s = ret.value();

    CHECK(s.size() == blocks*size);

    // there is not too much we can check. At least check that we have some different data inside string
    for (size_t i = 0 ; i < blocks; ++i) {
        for (size_t j = 0 ; j < blocks; ++j) {
            if (i == j) continue;
            CHECK(memcmp(s.data() + i*size, s.data() + j*size, size) != 0);
        }
    }
}

TEST("random async") {
    AsyncTest test(5000, 1);
    get_random(20, [&](auto& s, auto&, auto){
        test.happens();
        CHECK(s.size() == 20);
    }, test.loop);
    test.run();
}
