#include "error.h"
#include <openssl/err.h>
#include <openssl/ssl.h>

namespace panda { namespace unievent {

const ErrorCategory        error_category;
const SslErrorCategory     ssl_error_category;
const OpenSslErrorCategory openssl_error_category;

const char* ErrorCategory::name () const throw() { return "unievent"; }

std::string ErrorCategory::message (int condition) const throw() {
    switch ((errc)condition) {
        case errc::unknown_error                            : return "unknown error";
        case errc::read_start_error                         : return "read start error";
        case errc::ssl_error                                : return "ssl error";
        case errc::bind_error                               : return "bind error";
        case errc::listen_error                             : return "listen error";



        case errc::resolve_error                            : return "resolve error";
        case errc::ai_address_family_not_supported          : return "address family not supported";
        case errc::ai_temporary_failure                     : return "temporary failure";
        case errc::ai_bad_flags                             : return "bad ai_flags value";
        case errc::ai_bad_hints                             : return "invalid value for hints";
        case errc::ai_request_canceled                      : return "request canceled";
        case errc::ai_permanent_failure                     : return "permanent failure";
        case errc::ai_family_not_supported                  : return "ai_family not supported";
        case errc::ai_out_of_memory                         : return "out of memory";
        case errc::ai_no_address                            : return "no address";
        case errc::ai_unknown_node_or_service               : return "unknown node or service";
        case errc::ai_argument_buffer_overflow              : return "argument buffer overflow";
        case errc::ai_resolved_protocol_unknown             : return "resolved protocol is unknown";
        case errc::ai_service_not_available_for_socket_type : return "service not available for socket type";
        case errc::ai_socket_type_not_supported             : return "socket type not supported";
        case errc::invalid_unicode_character                : return "invalid Unicode character";
        case errc::not_on_network                           : return "machine is not on the network";
        case errc::transport_endpoint_shutdown              : return "cannot send after transport endpoint shutdown";
        case errc::host_down                                : return "host is down";
        case errc::remote_io                                : return "remote I/O error";
    }
    return {};
}


const char* SslErrorCategory::name () const throw() { return "unievent-ssl"; }

std::string SslErrorCategory::message (int) const throw() {
    return "generic ssl error";
}


const char* OpenSslErrorCategory::name () const throw() { return "unievent-openssl"; }

std::string OpenSslErrorCategory::message (int condition) const throw() {
    char buf[120];
    ERR_error_string_n((unsigned long)condition, buf, sizeof(buf));
    return std::string(buf, strlen(buf));
}


std::error_code make_ssl_error_code (int ssl_code) {
    if (ssl_code != SSL_ERROR_SSL) return std::error_code(ssl_code, ssl_error_category);
    unsigned long tmp, openssl_code = 0;
    while ((tmp = ERR_get_error())) openssl_code = tmp;
    return std::error_code((int)openssl_code, openssl_error_category);
}


Error::Error (const ErrorCode& ec) : ec(ec) {}

const ErrorCode& Error::code () const { return ec; }

string Error::whats () const noexcept {
    if (ec) return ec.what();
    return exception::whats();
}

Error* Error::clone () const {
    if (ec) return new Error(ec);
    return new Error(exception::whats());
}

}}
