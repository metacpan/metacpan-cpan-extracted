#include "exception.h"
#include <cstring>
#include <memory>
#include <functional>
#ifdef _WIN32
  #include "exception/win.icc"
#else
  #include "exception/unix.icc"
#endif

namespace panda {

static RawTraceProducer  rawtrace_producer = get_default_raw_producer();
static BacktraceProducer bt_producer       = get_default_bt_producer();

BacktraceInfo::~BacktraceInfo() {};

void Backtrace::install_producer(BacktraceProducer& producer_) {
    bt_producer = producer_;
}

Backtrace::Backtrace (const Backtrace& other) noexcept : buffer(other.buffer) {}
	
Backtrace::Backtrace () noexcept {
    void* temp_buff[max_depth];
    auto depth = rawtrace_producer(temp_buff, max_depth);
    if (depth) {
        buffer.resize(max_depth);
        std::memcpy(buffer.data(), temp_buff, sizeof(void*) * depth);
    }
}

Backtrace::~Backtrace() {}

iptr<BacktraceInfo> Backtrace::get_backtrace_info() const noexcept {
    return bt_producer(buffer);
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
