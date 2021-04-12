#pragma once
#include "log.h"
#include <iosfwd>
#include <stdint.h>
#include <type_traits>
#include <panda/error.h>
#include <panda/excepted.h>
#if defined(_WIN32)
    #include <winsock2.h>
#endif

#define UE_NULL_TERMINATE(what, to)         \
    char to[what.length()+1];               \
    memcpy(to, what.data(), what.length()); \
    to[what.length()] = 0;

namespace panda { namespace unievent {

#if defined(_WIN32)
    using fd_t   = int;
    using sock_t = SOCKET;
    using fh_t   = HANDLE;
    using uid_t  = long;
    using gid_t  = long;
#else
    using fd_t   = int;
    using sock_t = int;
    using fh_t   = int;
#endif

enum class Ownership {
    TRANSFER = 0,
    SHARE
};

struct TimeVal {
  int64_t sec;
  int32_t usec;

  double get () const { return (double)sec + (double)usec / 1000000; }

  TimeVal& operator= (double val) {
      sec  = val;
      usec = (val - sec) * 1000000;
      return *this;
  }

  bool operator== (const TimeVal& oth) const { return sec == oth.sec && usec == oth.usec; }
  bool operator!= (const TimeVal& oth) const { return !operator==(oth); }
  bool operator>= (const TimeVal& oth) const { return sec > oth.sec || (sec == oth.sec && usec >= oth.usec); }
  bool operator>  (const TimeVal& oth) const { return sec > oth.sec || (sec == oth.sec && usec > oth.usec); }
  bool operator<= (const TimeVal& oth) const { return !operator>(oth); }
  bool operator<  (const TimeVal& oth) const { return !operator>=(oth); }
};
std::ostream& operator<< (std::ostream& os, const TimeVal&);

struct TimeSpec {
    long sec;
    long nsec;

    double get () const { return (double)sec + (double)nsec / 1000000000; }

    TimeSpec& operator= (double val) {
        sec  = val;
        nsec = (val - sec) * 1000000000;
        return *this;
    }

    bool operator== (const TimeSpec& oth) const { return sec == oth.sec && nsec == oth.nsec; }
    bool operator!= (const TimeSpec& oth) const { return !operator==(oth); }
    bool operator>= (const TimeSpec& oth) const { return sec > oth.sec || (sec == oth.sec && nsec >= oth.nsec); }
    bool operator>  (const TimeSpec& oth) const { return sec > oth.sec || (sec == oth.sec && nsec > oth.nsec); }
    bool operator<= (const TimeSpec& oth) const { return !operator>(oth); }
    bool operator<  (const TimeSpec& oth) const { return !operator>=(oth); }
};
std::ostream& operator<< (std::ostream& os, const TimeSpec&);

template <class F1, class F2>
void scope_guard (F1&& code, F2&& guard) {
    try { code(); }
    catch (...) {
        guard();
        throw;
    }
    guard();
}

template <class T>
inline excepted<T, ErrorCode> handle_fd_excepted (const expected<T, std::error_code>& r) {
    if (r.has_value()) return r.value();

    std::error_code err = r.error();
    if (err == std::errc::not_connected || err == std::errc::bad_file_descriptor || err == std::errc::invalid_argument) {
        return T();
    }

    return make_unexpected(err);
}

}}
