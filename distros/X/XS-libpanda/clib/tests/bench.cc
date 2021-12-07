#include "test.h"
#include <panda/hash.h>
#include <catch2/benchmark/catch_benchmark.hpp>

TEST_PREFIX("bench: ", "[.]");

TEST("dyn_cast") {
    struct Base {
        int x;
        virtual ~Base() {}
    };
    struct Base1 : virtual Base { int a; };
    struct Base2 : virtual Base1 { int b; };
    struct Der   : virtual Base2 { int c; };

    struct ABC {
        int ttt;
        virtual ~ABC() {}
    };

    struct Epta : virtual Der, virtual ABC { int erc; };

    Base* b = new Epta();
    BENCHMARK("") {
        uint64_t res = 0;
        for (size_t i = 0; i < 1000; i++) {
            res += (uint64_t)dyn_cast<Base1*>(b);
        }
        return res;
    };
}

TEST("mempool", "[bench-mempool]") {
    MemoryPool pool(16);
    BENCHMARK("single") {
        uint64_t res = 0;
        for (size_t i = 0; i < 1000; i++) {
            auto p = pool.allocate();
            res += (uint64_t)p;
            pool.deallocate(p);
        }
        return res;
    };
    void* ptrs[1000];
    BENCHMARK("multi") {
        uint64_t res = 0;
        for (size_t i = 0; i < 1000; ++i) {
            ptrs[i] = pool.allocate();
            res += (uint64_t)ptrs[i];
        }
        for (size_t i = 0; i < 1000; ++i) {
            pool.deallocate(ptrs[i]);
        }
        return res;
    };
}

TEST("static_mempool", "[bench-mempool]") {
    BENCHMARK("instance") {
        uint64_t res = 0;
        for (size_t i = 0; i < 1000; i++) {
            res += (uint64_t)StaticMemoryPool<16>::instance();
        }
        return res;
    };
    BENCHMARK("single") {
        uint64_t res = 0;
        for (size_t i = 0; i < 1000; i++) {
            auto p = StaticMemoryPool<16>::instance()->allocate();
            res += (uint64_t)p;
            StaticMemoryPool<16>::instance()->deallocate(p);

        }
        return res;
    };
    void* ptrs[1000];
    BENCHMARK("multi") {
        uint64_t res = 0;
        for (size_t i = 0; i < 1000; ++i) {
            ptrs[i] = StaticMemoryPool<16>::allocate();
            res += (uint64_t)ptrs[i];
        }
        for (size_t i = 0; i < 1000; ++i) {
            StaticMemoryPool<16>::deallocate(ptrs[i]);
        }
        return res;
    };
}

TEST_CASE("dynamic_mempool", "[bench-mempool]") {
    BENCHMARK("instance") {
        uint64_t res = 0;
        for (size_t i = 0; i < 1000; i++) {
            res += (uint64_t)DynamicMemoryPool::instance();
        }
        return res;
    };
    BENCHMARK("single") {
        uint64_t res = 0;
        for (size_t i = 0; i < 1000; i++) {
            auto p = DynamicMemoryPool::instance()->allocate(16);
            res += (uint64_t)p;
            DynamicMemoryPool::instance()->deallocate(p, 16);

        }
        return res;
    };
}

TEST("allocated_object", "[bench-mempool]") {
    struct FastAlloc : AllocatedObject<FastAlloc> {
        int a;
        double b;
        uint64_t c;
        void* d;
    };

    BENCHMARK("single") {
        uint64_t res = 0;
        for (size_t i = 0; i < 1000; i++) {
            auto p = new FastAlloc();
            res += (uint64_t)p;
            delete p;

        }
        return res;
    };
    FastAlloc* ptrs[1000];
    BENCHMARK("multi") {
        uint64_t res = 0;
        for (size_t i = 0; i < 1000; ++i) {
            ptrs[i] = new FastAlloc();
            res += (uint64_t)ptrs[i];
        }
        for (size_t i = 0; i < 1000; ++i) {
            delete ptrs[i];
        }
        return res;
    };
}

TEST("hash") {
    string _str_long = string(1000, 'x');

    string_view str5    = "12345";
    string_view str10   = "1234567890";
    string_view str20   = "12345678901234567890";
    string_view str50   = "12345678901234567890123456789012345678901234567890";
    string_view str1000 = _str_long;
    string_view str1000ua = string_view(str1000.data() + 1, str1000.length() - 1);
    SECTION("murmur64a") {
        BENCHMARK("5")      { return hash::hash_murmur64a(str5); };
        BENCHMARK("10")     { return hash::hash_murmur64a(str10); };
        BENCHMARK("20")     { return hash::hash_murmur64a(str20); };
        BENCHMARK("50")     { return hash::hash_murmur64a(str50); };
        BENCHMARK("1000")   { return hash::hash_murmur64a(str1000); };
        BENCHMARK("1000ua") { return hash::hash_murmur64a(str1000ua); };
    }
    SECTION("jenkins_one_at_a_time") {
        BENCHMARK("5")    { return hash::hash_jenkins_one_at_a_time(str5); };
        BENCHMARK("10")   { return hash::hash_jenkins_one_at_a_time(str10); };
        BENCHMARK("20")   { return hash::hash_jenkins_one_at_a_time(str20); };
        BENCHMARK("50")   { return hash::hash_jenkins_one_at_a_time(str50); };
        BENCHMARK("1000") { return hash::hash_jenkins_one_at_a_time(str1000); };
    }
}
