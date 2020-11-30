#pragma once

#include <vector>
#include <cstdint>
#include <panda/string.h>


namespace panda { namespace backtrace {

struct SharedObjectInfo {
    std::uint64_t begin;
    std::uint64_t end;
    bool absolute;
    string name;


    SharedObjectInfo(std::uint64_t begin_, std::uint64_t end_, bool absolute_, string name_):
        begin{begin_}, end{end_}, absolute{absolute_}, name{name_}{}
    SharedObjectInfo(const SharedObjectInfo&) = default;
    SharedObjectInfo(SharedObjectInfo&&) = default;

    inline std::uint64_t get_offset(std::uint64_t ip) noexcept {
        return absolute ? ip : ip - begin;
    }
};

using SharedObjectMap = std::vector<SharedObjectInfo>;

}}
