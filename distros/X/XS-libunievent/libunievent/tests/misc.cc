#include "lib/test.h"

TEST_CASE("hostname", "[misc]") {
    auto h = hostname();
    CHECK(h);
}

TEST_CASE("get_rss", "[misc]") {
    auto rss = get_rss();
    CHECK(rss > 0);
    std::vector<int> v;
    for (int i = 0; i < 100000; ++i) v.push_back(1);
    auto new_rss = get_rss();
    CHECK(new_rss > rss);
}

TEST_CASE("get_free_memory", "[misc]") {
    auto val = get_free_memory();
    CHECK(val > 0);
}

TEST_CASE("get_total_memory", "[misc]") {
    auto val = get_total_memory();
    CHECK(val > get_free_memory());
}

TEST_CASE("cpu_info", "[misc]") {
    auto list = cpu_info();
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

TEST_CASE("interface info", "[misc]") {
    auto list = interface_info();
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

TEST_CASE("get_rusage", "[.][misc]") {
    auto rusage = get_rusage();
    CHECK(rusage.maxrss > 0);
}
