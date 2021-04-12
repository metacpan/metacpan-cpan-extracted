#pragma once
#include <system_error>

namespace panda { namespace unievent { namespace socks {

enum class errc {
    socks_error = 1,
    protocol_error,
    no_acceptable_auth_method,
};

struct ErrorCategory : std::error_category {
    const char* name () const throw() override;
    std::string message (int condition) const throw() override;
};

extern const ErrorCategory error_category;

inline std::error_code make_error_code (errc code) { return std::error_code((int)code, error_category); }

}}}

namespace std {
    template <> struct is_error_code_enum<panda::unievent::socks::errc> : true_type {};
}
