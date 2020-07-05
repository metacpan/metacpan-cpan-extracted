#pragma once
#include "inc.h"
#include <system_error>
#include <panda/error.h>
#include <panda/string.h>
#include <panda/exception.h>
#include <panda/string_view.h>

namespace panda { namespace unievent {

using panda::ErrorCode;

enum class errc {
    unknown_error = 1,
    read_start_error,
    bind_error,
    listen_error,
    ssl_error,
    resolve_error,
    // errors below are used only for UV error translation (absent in std::errc). Not sure if they may happen really
    ai_address_family_not_supported,
    ai_temporary_failure,
    ai_bad_flags,
    ai_bad_hints,
    ai_request_canceled,
    ai_permanent_failure,
    ai_family_not_supported,
    ai_out_of_memory,
    ai_no_address,
    ai_unknown_node_or_service,
    ai_argument_buffer_overflow,
    ai_resolved_protocol_unknown,
    ai_service_not_available_for_socket_type,
    ai_socket_type_not_supported,
    invalid_unicode_character,
    not_on_network,
    transport_endpoint_shutdown,
    host_down,
    remote_io,
};

enum class resolve_errc {
    host_not_found = 1,
    not_implemented,
    service_not_found,
    no_data,
    bad_format,
    server_failed,
    refused,
    bad_query,
    bad_name,
    bad_response,
    eof,
    file_read_error,
    bad_string,
    bad_flags,
    noname,
    bad_hints,
    not_initialized,
    iphlpapi_load_error,
    no_get_network_params,
};

struct ErrorCategory : std::error_category {
    const char* name () const throw() override;
    std::string message (int condition) const throw() override;
};
struct ResolveErrorCategory : std::error_category {
    const char* name () const throw() override;
    std::string message (int condition) const throw() override;
};
struct SslErrorCategory : std::error_category {
    const char* name () const throw() override;
    std::string message (int condition) const throw() override;
};
struct OpenSslErrorCategory : std::error_category {
    const char* name () const throw() override;
    std::string message (int condition) const throw() override;
};

extern const ErrorCategory        error_category;
extern const ResolveErrorCategory resolve_error_category;
extern const SslErrorCategory     ssl_error_category;
extern const OpenSslErrorCategory openssl_error_category;

inline std::error_code make_error_code (errc         code) { return std::error_code((int)code, error_category); }
inline std::error_code make_error_code (resolve_errc code) { return std::error_code((int)code, resolve_error_category); }

std::error_code make_ssl_error_code (int ssl_code);

inline ErrorCode nest_error (const std::error_code& err, const ErrorCode& stack) {
    if (!stack) return stack;
    return stack & std::errc::operation_canceled ? stack : ErrorCode(err, stack);
}


struct Error : panda::exception {
    using exception::exception;
    Error (const ErrorCode& ec);

    const ErrorCode& code () const;

    virtual string whats () const noexcept override;
    virtual Error* clone () const;

protected:
    ErrorCode ec;
};

}}

namespace std {
    template <> struct is_error_code_enum<panda::unievent::errc>         : true_type {};
    template <> struct is_error_code_enum<panda::unievent::resolve_errc> : true_type {};
}
