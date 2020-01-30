#include "test.h"

using namespace panda;

struct Base {
    int x;
    virtual ~Base() {}
};

struct Base1 : virtual Base {
    int a;
};

struct Base2 : virtual Base1 {
    int b;
};

struct Der : virtual Base2 {
    int c;
};

struct ABC {
    int ttt;
    virtual ~ABC() {}
};

struct Epta : virtual Der, virtual ABC {
    int erc;
};

struct Wrong {
    virtual ~Wrong() {}
};

struct FastAlloc : AllocatedObject<FastAlloc> {
    int a;
    double b;
    uint64_t c;
    void* d;
};


Base* get_suka () { return new Epta(); }

TEST_CASE("dyn_cast", "[!benchmark]") {
    Base* b = get_suka();
    uint64_t res = 0;
    BENCHMARK("dyn_cast") {
        for (size_t i = 0; i < 1000000000; i++) {
            res += (uint64_t)dyn_cast<Base1*>(b);
        }
    }
    WARN(res);
}

TEST_CASE("bench_mempool_single", "[bench-mempool]") {
    MemoryPool pool(16);
    uint64_t res = 0;
    for (size_t i = 0; i < 1000000000; i++) {
        auto p = pool.allocate();
        res += (uint64_t)p;
        pool.deallocate(p);

    }
    WARN(res);
}

TEST_CASE("bench_mempool_multi", "[bench-mempool]") {
    MemoryPool pool(16);
    uint64_t res = 0;
    void* ptrs[1000];
    for (size_t j = 0; j < 1000000; ++j) {
        for (size_t i = 0; i < 1000; ++i) {
            ptrs[i] = pool.allocate();
            res += (uint64_t)ptrs[i];
        }
        for (size_t i = 0; i < 1000; ++i) {
            pool.deallocate(ptrs[i]);
        }
    }
    WARN(res);
}

TEST_CASE("bench_static_mempool_instance", "[bench-mempool]") {
    uint64_t res = 0;
    for (size_t i = 0; i < 1000000000; i++) {
        res += (uint64_t)StaticMemoryPool<16>::instance();
    }
    WARN(res);
}

TEST_CASE("bench_static_mempool_single", "[bench-mempool]") {
    uint64_t res = 0;
    for (size_t i = 0; i < 1000000000; i++) {
        auto p = StaticMemoryPool<16>::instance()->allocate();
        res += (uint64_t)p;
        StaticMemoryPool<16>::instance()->deallocate(p);

    }
    WARN(res);
}

TEST_CASE("bench_static_mempool_multi", "[bench-mempool]") {
    uint64_t res = 0;
    void* ptrs[1000];
    for (size_t j = 0; j < 1000000; ++j) {
        for (size_t i = 0; i < 1000; ++i) {
            ptrs[i] = StaticMemoryPool<16>::allocate();
            res += (uint64_t)ptrs[i];
        }
        for (size_t i = 0; i < 1000; ++i) {
            StaticMemoryPool<16>::deallocate(ptrs[i]);
        }
    }
    WARN(res);
}

TEST_CASE("bench_dynamic_mempool_instance", "[bench-mempool]") {
    uint64_t res = 0;
    for (size_t i = 0; i < 1000000000; i++) {
        res += (uint64_t)DynamicMemoryPool::instance();
    }
    WARN(res);
}

TEST_CASE("bench_dynamic_mempool_single", "[bench-mempool]") {
    uint64_t res = 0;
    for (size_t i = 0; i < 1000000000; i++) {
        auto p = DynamicMemoryPool::instance()->allocate(16);
        res += (uint64_t)p;
        DynamicMemoryPool::instance()->deallocate(p, 16);

    }
    WARN(res);
}

TEST_CASE("bench_pool_obj_single", "[bench-mempool]") {
    uint64_t res = 0;
    for (size_t i = 0; i < 1000000000; i++) {
        auto p = new FastAlloc();
        res += (uint64_t)p;
        delete p;

    }
    WARN(res);
}

TEST_CASE("bench_pool_obj_multi", "[bench-mempool]") {
    uint64_t res = 0;
    FastAlloc* ptrs[1000];
    for (size_t j = 0; j < 1000000; ++j) {
        for (size_t i = 0; i < 1000; ++i) {
            ptrs[i] = new FastAlloc();
            res += (uint64_t)ptrs[i];
        }
        for (size_t i = 0; i < 1000; ++i) {
            delete ptrs[i];
        }
    }
    WARN(res);
}
