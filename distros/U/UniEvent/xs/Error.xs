#include <xs/export.h>
#include <xs/unievent/error.h>

using namespace xs;
using namespace panda::unievent;
using panda::string;
using panda::string_view;

struct ErrorConstantRow {
    string_view     name;
    std::error_code value;
    template <class T> ErrorConstantRow (string_view n, T val) : name(n), value(make_error_code(val)) {}
};

static void create_error_constants (Stash stash, std::initializer_list<ErrorConstantRow> l) {
    for (auto& row : l) stash.add_const_sub(row.name, xs::out(row.value));
}

MODULE = UniEvent::Error                PACKAGE = UniEvent::Error
PROTOTYPES: DISABLE

BOOT {
    Stash error_stash(__PACKAGE__);
    
    Stash("UniEvent")["SystemError::"] = Stash("XS::STL")["errc::"];
    
    error_stash.add_const_sub("category", xs::out<const std::error_category*>(&error_category));
    error_stash.add_const_sub("system_category", xs::out<const std::error_category*>(&make_error_code(std::errc::timed_out).category()));
    error_stash.add_const_sub("ssl_category", xs::out<const std::error_category*>(&ssl_error_category));
    error_stash.add_const_sub("openssl_category", xs::out<const std::error_category*>(&openssl_error_category));
    
    create_error_constants(error_stash, {
        {"unknown_error",                               errc::unknown_error},
        {"read_start_error",                            errc::read_start_error},
        {"ssl_error",                                   errc::ssl_error},
        {"resolve_error",                               errc::resolve_error},
        //
        {"ai_address_family_not_supported",             errc::ai_address_family_not_supported},
        {"ai_temporary_failure",                        errc::ai_temporary_failure},
        {"ai_bad_flags",                                errc::ai_bad_flags},
        {"ai_bad_hints",                                errc::ai_bad_hints},
        {"ai_request_canceled",                         errc::ai_request_canceled},
        {"ai_permanent_failure",                        errc::ai_permanent_failure},
        {"ai_family_not_supported",                     errc::ai_family_not_supported},
        {"ai_out_of_memory",                            errc::ai_out_of_memory},
        {"ai_no_address",                               errc::ai_no_address},
        {"ai_unknown_node_or_service",                  errc::ai_unknown_node_or_service},
        {"ai_argument_buffer_overflow",                 errc::ai_argument_buffer_overflow},
        {"ai_resolved_protocol_unknown",                errc::ai_resolved_protocol_unknown},
        {"ai_service_not_available_for_socket_type",    errc::ai_service_not_available_for_socket_type},
        {"ai_socket_type_not_supported",                errc::ai_socket_type_not_supported},
        {"invalid_unicode_character",                   errc::invalid_unicode_character},
        {"not_on_network",                              errc::not_on_network},
        {"transport_endpoint_shutdown",                 errc::transport_endpoint_shutdown},
        {"host_down",                                   errc::host_down},
        {"remote_io",                                   errc::remote_io},
    });
}

const Error* Error::new (Sv arg) {
    if (arg.is_object_ref()) RETVAL = new Error(xs::in<panda::ErrorCode>(arg));
    else                     RETVAL = new Error(xs::in<string>(arg));
}

panda::ErrorCode Error::code () : const

string Error::what (...) : const

Error* Error::clone () : const {
    PROTO = Object(ST(0)).stash();
    RETVAL = THIS->clone();
}
