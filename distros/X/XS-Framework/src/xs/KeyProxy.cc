#include <xs/KeyProxy.h>
#include <xs/Hash.h>
#include <xs/Array.h>

namespace xs {

KeyProxy KeyProxy::operator[] (size_t key) {
    if (SvROK(sv)) {
        Array a(SvRV(sv));
        if (a) return a[key];
    }
    throw std::invalid_argument("element is not an array reference");
}

KeyProxy KeyProxy::operator[] (const panda::string_view& key) {
    if (SvROK(sv)) {
        Hash h(SvRV(sv));
        if (h) return h[key];
    }
    throw std::invalid_argument("element is not a hash reference");
}

}
