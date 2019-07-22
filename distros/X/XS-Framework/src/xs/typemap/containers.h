#pragma once
#include "base.h"
#include "../Hash.h"
#include "../Array.h"
#include "../Simple.h"
#include <map>
#include <vector>

namespace xs {

namespace typemap { namespace containers {
    inline const panda::string& to_key (const panda::string& value) { return value; }
    inline panda::string_view   to_key (const std::string& value)   { return panda::string_view(value.data(), value.size()); }

    template <typename T>
    panda::string to_key (T&& value) { return panda::to_string(std::forward<T>(value)); }
}}

template <typename T> struct VectorTypemap : TypemapBase<std::vector<T>> {
    static Sv out(pTHX_ const std::vector<T>& data, const Sv& = {}){
        auto out = Array::create(data.size());
        for(const auto& i : data){
            out.push(xs::out(i));
        }
        return Ref::create(out);
    }

    static std::vector<T> in (pTHX_ Array arg){
        std::vector<T> out;
        out.reserve(arg.size());
        for(const auto& i : arg){
            out.emplace_back(xs::in<T>(i));
        }
        return out;
    }
};

template <typename T> struct Typemap<std::vector<T>> : VectorTypemap<T> {};

template <typename K, typename V> struct Typemap<std::map<K,V>, std::map<K,V>> : TypemapBase<std::map<K,V>> {
    static Sv out (pTHX_ const std::map<K,V>& data, const Sv& = {}) {
        auto out = Hash::create(data.size());
        for(const auto& i : data){
            auto key = typemap::containers::to_key(i.first);
            out.store(key, xs::out(i.second));
        }
        return Ref::create(out);
    }

    static std::map<K,V> in (pTHX_ Hash arg) {
        std::map<K,V> out;
        for (const auto& element : arg){
            K key = xs::in<K>(Simple(element.key()));
            V value = xs::in<V>(element.value());
            out.emplace(key, value);
        }
        return out;
    }
};

}
