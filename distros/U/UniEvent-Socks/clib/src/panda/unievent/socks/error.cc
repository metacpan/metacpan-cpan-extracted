#include "error.h"

namespace panda { namespace unievent { namespace socks {

const ErrorCategory error_category;

const char* ErrorCategory::name () const throw() { return "unievent-socks"; }

std::string ErrorCategory::message (int condition) const noexcept {
    switch ((errc)condition) {
        case errc::socks_error               : return "socks error";
        case errc::protocol_error            : return "protocol error";
        case errc::no_acceptable_auth_method : return "no acceptable auth method";
    }
    return {};
}

}}}
