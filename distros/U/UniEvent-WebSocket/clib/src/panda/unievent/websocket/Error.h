#pragma once

#include <panda/error.h>
#include <panda/log.h>

namespace panda { namespace unievent { namespace websocket {

enum class errc {
    READ_ERROR = 1,
    WRITE_ERROR,
    CONNECT_ERROR
};

extern const std::error_category& ws_error_category;

inline std::error_code make_error_code(errc err) noexcept {
    return std::error_code(int(err), ws_error_category);
}

extern log::Module panda_log_module;

}}}

namespace std {
template <> struct is_error_code_enum<panda::unievent::websocket::errc> : std::true_type {};
}

