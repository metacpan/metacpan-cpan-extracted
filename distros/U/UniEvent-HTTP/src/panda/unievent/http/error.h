#pragma once
#include <system_error>
#include <panda/exception.h>
#include <panda/unievent/error.h>

namespace panda { namespace unievent { namespace http {

enum class errc {
    connect_error = 1,
    no_redirect_uri,
    redirection_limit,
    unexpected_redirect,
    transfer_aborted,
    server_stopping,
    pipeline_canceled,
};

struct ErrorCategory : std::error_category {
    const char* name () const throw() override;
    std::string message (int condition) const throw() override;
};
extern const ErrorCategory error_category;

inline std::error_code make_error_code (errc code) { return std::error_code((int)code, error_category); }

struct HttpError : panda::exception {
    using exception::exception;
};

}}}

namespace std {
    template <>
    struct is_error_code_enum<panda::unievent::http::errc> : true_type {};
}
