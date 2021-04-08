#pragma once
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include "string_view/defs.h"

namespace panda { namespace hash {

uint64_t hash_murmur64a             (string_view);
uint32_t hash_jenkins_one_at_a_time (string_view);

inline uint64_t hash64 (string_view v) { return hash_murmur64a(v); }
inline uint32_t hash32 (string_view v) { return hash_jenkins_one_at_a_time(v); }

namespace {
    template <int T> struct _hashXX;
    template <> struct _hashXX<4> { uint32_t operator() (string_view v) { return hash32(v); } };
    template <> struct _hashXX<8> { uint64_t operator() (string_view v) { return hash64(v); } };
}

template <typename T = size_t> inline T hashXX (string_view);
template <> inline unsigned           hashXX<unsigned>           (string_view v) { return _hashXX<sizeof(unsigned)>()(v); }
template <> inline unsigned long      hashXX<unsigned long>      (string_view v) { return _hashXX<sizeof(unsigned long)>()(v); }
template <> inline unsigned long long hashXX<unsigned long long> (string_view v) { return _hashXX<sizeof(unsigned long long)>()(v); }

}}

#include "string_view.h"
