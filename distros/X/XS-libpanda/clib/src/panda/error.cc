#include "error.h"
#include <map>
#include <iostream>

namespace panda {
namespace error {

static thread_local std::map<std::pair<const std::error_category*, const ErrorCode::NestedCategory*>, ErrorCode::NestedCategory> _cache;

static const ErrorCode::NestedCategory& get_nested_category (const std::error_category& self, const ErrorCode::NestedCategory* next) {
    auto& cache = _cache;
    auto iter = cache.find({&self, next});
    if (iter != cache.end()) {
        return iter->second;
    } else {
        return cache.insert({{&self, next}, {self, next}}).first->second;
    }
}

void ErrorCode::init () {
    if (data) {
        data->codes.clear();
        data->cat = nullptr;
    }
    else data = new Data();
}

void ErrorCode::push (const std::error_code& ec) {
    data->codes.push(ec.value());
    data->cat = &get_nested_category(ec.category(), data->cat);
}

bool ErrorCode::contains_impl(const std::error_code &c) const {
    const NestedCategory* cat = data->cat;
    for (auto v : data->codes) {
        if (v == c.value() && cat->self == c.category()) {
            return true;
        }
        cat = cat->next;
    }
    return false;
}

void ErrorCode::set (const std::error_code& ec) {
    init();
    push(ec);
}

void ErrorCode::set (const std::error_code& ec, const std::error_code& next) {
    init();
    if (next) push(next);
    push(ec);
}

void ErrorCode::set (const std::error_code& ec, const ErrorCode& next) {
    init();
    if (next) {
        data->codes = next.data->codes;
        data->cat   = next.data->cat;
    }
    push(ec);
}

std::string ErrorCode::message () const {
    if (!data) return std::system_category().message(0);
    return data->cat->self.message(data->codes.top());
}

ErrorCode ErrorCode::next () const noexcept {
    if (!data || !data->cat->next) return {};
    ErrorCode ret;
    ret.init();
    ret.data->codes = data->codes;
    ret.data->codes.pop();
    ret.data->cat = data->cat->next;
    return ret;
}

string ErrorCode::what () const {
    if (!data) return {};

    auto stack = data->codes;
    auto cat   = data->cat;

    string ret(stack.size() * 50);

    int i = 0;
    while (cat) {
        auto val = stack.top();
        if (i) ret += " -> ";
        ret += cat->self.message(val).c_str();
        ret += " (";
        ret += to_string(val);
        ret += ":";
        ret += cat->self.name();
        ret += ")";
        cat = cat->next;
        stack.pop();
        ++i;
    }

    return ret;
}

std::ostream& operator<< (std::ostream& os, const ErrorCode& ec) {
    return os << ec.what();
}

}}
