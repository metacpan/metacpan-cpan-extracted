#pragma once

#include <panda/string.h>

namespace panda {

inline string varint_encode(uint32_t i) {
    char c[8];
    int idx = 0;
    while (i > 127) {
        c[idx++] = 0x80 | uint8_t(i & 0x7F);
        i >>= 7;
    }
    c[idx++] = uint8_t(i);
    return string(c, idx);
}

inline uint32_t _varint_decode(const char*& ptr, const char* end) {
    size_t i = 0;
    uint32_t r = 0;
    while (ptr != end && (*ptr & 0x80)) {
        r |= (*ptr & 0x7f) << 7*i;
        ++i;
        ptr++;
    }
    r |= (*ptr & 0x7f) << 7*i;
    ++ptr;
    return r;
}

inline uint32_t varint_decode(const string& str, size_t start = 0) {
    auto begin = str.data() + start;
    return _varint_decode(begin, str.data() + str.length());
}

inline string varint_encode_s(int32_t i) {
    ////ZigZag encoding, x86 (both 32,64) only, uses signed bit shift
    //return varint_encode((i << 1) ^ (i >> 31));
    // make sanitizer happy with less efficient code. TODO: use some lib for that
    return varint_encode(i >= 0 ? (uint32_t)(i * 2) : ((uint32_t)(-i)*2 - 1));
}

inline int32_t _varint_decode_s(const char*& ptr, const char* end) {
    //ZigZag decoding
    uint32_t i = _varint_decode(ptr, end);
    return ((i >> 1) ^ -(i & 1));
}

inline int32_t varint_decode_s(const string& str) {
    auto begin = str.data();
    return _varint_decode_s(begin, str.data() + str.length());
}

struct VarIntStack {
    string storage;

    struct const_iterator {
        const char* ptr;

        using size_type         = size_t;
        using value_type        = int;
        using reference         = int&;
        using pointer           = int*;
        using difference_type   = std::ptrdiff_t;
        using iterator_category = std::forward_iterator_tag;

        int operator*() const {
            auto copy = ptr; // to prevent ptr from moving
            return _varint_decode_s(copy, nullptr); // unsafe end
        }

        const_iterator& operator++ () {
            _varint_decode_s(ptr, nullptr);
            return *this;
        }

        const_iterator operator++ (int) {
            auto res = *this;
            _varint_decode_s(ptr, nullptr);
            return res;
        }

        bool operator== (const const_iterator& oth) const {return ptr == oth.ptr;}
        bool operator!= (const const_iterator& oth) const {return !operator ==(oth);}
    };

    VarIntStack() = default;
    VarIntStack(const VarIntStack&) = default;
    VarIntStack(VarIntStack&&) = default;
    ~VarIntStack() = default;

    VarIntStack& operator=(const VarIntStack&) = default;
    VarIntStack& operator=(VarIntStack&&) = default;

    void push(int32_t val) {
        storage.insert(0, varint_encode_s(val));
    }
    void pop() {
        storage.offset(size_of_first());
    }

    int32_t top() const {
        return varint_decode_s(storage.substr(0, size_of_first()));
    }
    size_t size() const {
        size_t res = 0;
        for (char c : storage) {
            if (!(c&0x80)) {
                res += 1;
            }
        }
        return res;
    }

    void clear () {
        storage.clear();
    }

    bool empty() const {
        return storage.empty();
    }

    const_iterator begin() const {
        return const_iterator{storage.data()};
    }

    const_iterator end() const {
        return const_iterator{storage.data() + storage.length()};
    }

private:
    size_t size_of_first() const {
        size_t pos = 0;
        for (; pos < storage.size(); ++pos) {
            if (!(storage[pos] & 0x80)) {
                break;
            }
        }
        return pos + 1;
    }
};

}
