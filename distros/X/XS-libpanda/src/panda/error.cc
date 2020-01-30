#include "error.h"

namespace panda { namespace error {

const NestedCategory& get_nested_categoty(const std::error_category& self, const NestedCategory* next) {
    static thread_local std::map<std::pair<const std::error_category*, const NestedCategory*>, NestedCategory> cache;
    auto iter = cache.find({&self, next});
    if (iter != cache.end()) {
        return iter->second;
    } else {
        return cache.emplace(std::piecewise_construct,
                             std::forward_as_tuple(&self, next),
                             std::forward_as_tuple(self, next)).first->second;
    }
}

}}
