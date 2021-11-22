#pragma once
#include "string.h"
#include <panda/memory.h>

using panda::DynamicMemoryPool;

namespace ragel_fix_leaks {
    struct AntiLeakPool {
        DynamicMemoryPool  pool;
        std::vector<void*> big;

        void* allocate (size_t size) {
            if (size <= 262144) return pool.allocate(size);
            else {
                auto ret = malloc(size);
                if (ret) big.push_back(ret);
                return ret;
            }
        }

        void deallocate (void*, size_t) {
            // we don't deallocate because ragel somewhere frees what it still needs
            //if (size <= 262144) pool.deallocate(p, size);
        }

        void* reallocate (void* p, size_t oldsz, size_t newsz) {
            auto ret = allocate(newsz);
            memcpy(ret, p, oldsz > newsz ? newsz : oldsz);
            deallocate(p, oldsz);
            return ret;
        }

        ~AntiLeakPool () {
            for (auto ptr : big) free(ptr);
        }
    };
    extern thread_local AntiLeakPool* anti_leak_pool;

    template <class TARGET>
    struct TmpObject {
        static void* operator new (size_t, void* p) { return p; }

        static void* operator new (size_t size) {
            return anti_leak_pool->allocate(size);
        }

        static void operator delete (void* p, size_t size) {
            anti_leak_pool->deallocate(p, size);
        }
    };
}

using ragel_fix_leaks::TmpObject;
using ragel_fix_leaks::anti_leak_pool;
