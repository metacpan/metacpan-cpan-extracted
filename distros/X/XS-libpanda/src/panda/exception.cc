#include "exception.h"
#include <cstring>
#include <memory>
#include <functional>

#if defined(__unix__)
  #include <execinfo.h>
#endif

namespace panda {


BacktraceInfo::~BacktraceInfo() {};

static BacktraceProducer* producer = nullptr;

void Backtrace::install_producer(BacktraceProducer& producer_) {
    producer = &producer_;
}

Backtrace::Backtrace (const Backtrace& other) noexcept : buffer(other.buffer) {}
	
#if defined(__unix__)

Backtrace::Backtrace () noexcept {
    buffer.resize(max_depth);
    auto depth = ::backtrace(buffer.data(), max_depth);
    if (depth <= 0) {
        buffer.clear();
        return;
    } 
    buffer.resize(depth);
}

#else

Backtrace::Backtrace () noexcept {}

#endif

Backtrace::~Backtrace() {}

iptr<BacktraceInfo> Backtrace::get_backtrace_info() const noexcept {
    if (producer) { return (*producer)(buffer); }
    return iptr<BacktraceInfo>();
}

exception::exception () noexcept {}

exception::exception (const string& whats) noexcept : _whats(whats) {}

exception::exception (const exception& oth) noexcept : Backtrace(oth), _whats(oth._whats) {}

exception& exception::operator= (const exception& oth) noexcept {
    _whats = oth._whats;
    Backtrace::operator=(oth);
    return *this;
}

const char* exception::what () const noexcept {
    _whats = whats();
    return _whats.c_str();
}

string exception::whats () const noexcept {
    return _whats;
}

}
