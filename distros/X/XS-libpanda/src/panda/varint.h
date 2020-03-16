#pragma once

#include <panda/string.h>

namespace panda {

inline string varint_encode(uint32_t i) {
    string res;
    while (i > 127) {
        res += 0x80 | uint8_t(i & 0x7F);
        i >>= 7;
    }
    res += uint8_t(i);
    return res;
}

inline uint32_t varint_decode(const string& str) {
    size_t i = 0;
    uint32_t r = 0;
    while (i < str.size() && (str[i] & 0x80)) {
        r |= (str[i] & 0x7f) << 7*i;
        ++i;
    }
    r |= (str[i] & 0x7f) << 7*i;
    return r;
}

inline string varint_encode_s(int32_t i) {
    //ZigZag encoding, x86 (both 32,64) only, uses signed bit shift
    return varint_encode((i << 1) ^ (i >> 31));
}

inline int32_t varint_decode_s(const string& str) {
    //ZigZag decoding
    uint32_t i = varint_decode(str);
    return ((i >> 1) ^ -(i & 1));
}

struct VarIntStack {
    string storage;

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
