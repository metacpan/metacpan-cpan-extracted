#include <xs.h>
#include <ios>
#include <future>

using namespace xs;

#if !defined(_WIN32) && !defined(__DragonFly__) && !defined(__NetBSD__)
  #define _XSFW_SKIP_CHECK 1
#endif

void register_error_constants () {
    struct ecdata {
        panda::string_view long_name;
        panda::string_view short_name;
        std::errc          value;
    };
    
    Stash errc_stash("XS::STL::errc", GV_ADD);
    std::initializer_list<ecdata> list = {
        {"address_family_not_supported",        "EAFNOSUPPORT",     std::errc::address_family_not_supported},
        {"address_in_use",                      "EADDRINUSE",       std::errc::address_in_use},
        {"address_not_available",               "EADDRNOTAVAIL",    std::errc::address_not_available},
        {"already_connected",                   "EISCONN",          std::errc::already_connected},
        {"argument_list_too_long",              "E2BIG",            std::errc::argument_list_too_long},
        {"argument_out_of_domain",              "EDOM",             std::errc::argument_out_of_domain},
        {"bad_address",                         "EFAULT",           std::errc::bad_address},
        {"bad_file_descriptor",                 "EBADF",            std::errc::bad_file_descriptor},
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_EBADMSG)
        {"bad_message",                         "EBADMSG",          std::errc::bad_message},
        #endif
        {"broken_pipe",                         "EPIPE",            std::errc::broken_pipe},
        {"connection_aborted",                  "ECONNABORTED",     std::errc::connection_aborted},
        {"connection_already_in_progress",      "EALREADY",         std::errc::connection_already_in_progress},
        {"connection_refused",                  "ECONNREFUSED",     std::errc::connection_refused},
        {"connection_reset",                    "ECONNRESET",       std::errc::connection_reset},
        {"cross_device_link",                   "EXDEV",            std::errc::cross_device_link},
        {"destination_address_required",        "EDESTADDRREQ",     std::errc::destination_address_required},
        {"device_or_resource_busy",             "EBUSY",            std::errc::device_or_resource_busy},
        {"directory_not_empty",                 "ENOTEMPTY",        std::errc::directory_not_empty},
        {"executable_format_error",             "ENOEXEC",          std::errc::executable_format_error},
        {"file_exists",                         "EEXIST",           std::errc::file_exists},
        {"file_too_large",                      "EFBIG",            std::errc::file_too_large},
        {"filename_too_long",                   "ENAMETOOLONG",     std::errc::filename_too_long},
        {"function_not_supported",              "ENOSYS",           std::errc::function_not_supported},
        {"host_unreachable",                    "EHOSTUNREACH",     std::errc::host_unreachable},
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_EIDRM)
        {"identifier_removed",                  "EIDRM",            std::errc::identifier_removed},
        #endif
        {"illegal_byte_sequence",               "EILSEQ",           std::errc::illegal_byte_sequence},
        {"inappropriate_io_control_operation",  "ENOTTY",           std::errc::inappropriate_io_control_operation},
        {"interrupted",                         "EINTR",            std::errc::interrupted},
        {"invalid_argument",                    "EINVAL",           std::errc::invalid_argument},
        {"invalid_seek",                        "ESPIPE",           std::errc::invalid_seek},
        {"io_error",                            "EIO",              std::errc::io_error},
        {"is_a_directory",                      "EISDIR",           std::errc::is_a_directory},
        {"message_size",                        "EMSGSIZE",         std::errc::message_size},
        {"network_down",                        "ENETDOWN",         std::errc::network_down},
        {"network_reset",                       "ENETRESET",        std::errc::network_reset},
        {"network_unreachable",                 "ENETUNREACH",      std::errc::network_unreachable},
        {"no_buffer_space",                     "ENOBUFS",          std::errc::no_buffer_space},
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_ECHILD)
        {"no_child_process",                    "ECHILD",           std::errc::no_child_process},
        #endif
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_ENOLINK)
        {"no_link",                             "ENOLINK",          std::errc::no_link},
        #endif
        {"no_lock_available",                   "ENOLCK",           std::errc::no_lock_available},
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_ENODATA)
        {"no_message_available",                "ENODATA",          std::errc::no_message_available},
        #endif
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_ENOMSG)
        {"no_message",                          "ENOMSG",           std::errc::no_message},
        #endif
        {"no_protocol_option",                  "ENOPROTOOPT",      std::errc::no_protocol_option},
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_ENOSPC)
        {"no_space_on_device",                  "ENOSPC",           std::errc::no_space_on_device},
        #endif
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_ENOSR)
        {"no_stream_resources",                 "ENOSR",            std::errc::no_stream_resources},
        #endif
        {"no_such_device_or_address",           "ENXIO",            std::errc::no_such_device_or_address},
        {"no_such_device",                      "ENODEV",           std::errc::no_such_device},
        {"no_such_file_or_directory",           "ENOENT",           std::errc::no_such_file_or_directory},
        {"no_such_process",                     "ESRCH",            std::errc::no_such_process},
        {"not_a_directory",                     "ENOTDIR",          std::errc::not_a_directory},
        {"not_a_socket",                        "ENOTSOCK",         std::errc::not_a_socket},
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_ENOSTR)
        {"not_a_stream",                        "ENOSTR",           std::errc::not_a_stream},
        #endif
        {"not_connected",                       "ENOTCONN",         std::errc::not_connected},
        {"not_enough_memory",                   "ENOMEM",           std::errc::not_enough_memory},
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_ENOTSUP)
        {"not_supported",                       "ENOTSUP",          std::errc::not_supported},
        #endif
        {"operation_canceled",                  "ECANCELED",        std::errc::operation_canceled},
        {"operation_in_progress",               "EINPROGRESS",      std::errc::operation_in_progress},
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_EPERM)
        {"operation_not_permitted",             "EPERM",            std::errc::operation_not_permitted},
        #endif
        {"operation_not_supported",             "EOPNOTSUPP",       std::errc::operation_not_supported},
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_EWOULDBLOCK)
        {"operation_would_block",               "EWOULDBLOCK",      std::errc::operation_would_block},
        #endif
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_EOWNERDEAD)
        {"owner_dead",                          "EOWNERDEAD",       std::errc::owner_dead},
        #endif
        {"permission_denied",                   "EACCES",           std::errc::permission_denied},
        {"protocol_error",                      "EPROTO",           std::errc::protocol_error},
        {"protocol_not_supported",              "EPROTONOSUPPORT",  std::errc::protocol_not_supported},
        {"read_only_file_system",               "EROFS",            std::errc::read_only_file_system},
        {"resource_deadlock_would_occur",       "EDEADLK",          std::errc::resource_deadlock_would_occur},
        {"resource_unavailable_try_again",      "EAGAIN",           std::errc::resource_unavailable_try_again},
        {"result_out_of_range",                 "ERANGE",           std::errc::result_out_of_range},
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_ENOTRECOVERABLE)
        {"state_not_recoverable",               "ENOTRECOVERABLE",  std::errc::state_not_recoverable},
        #endif
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_ETIME)
        {"stream_timeout",                      "ETIME",            std::errc::stream_timeout},
        #endif
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_ETXTBSY)
        {"text_file_busy",                      "ETXTBSY",          std::errc::text_file_busy},
        #endif
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_ETIMEDOUT)
        {"timed_out",                           "ETIMEDOUT",        std::errc::timed_out},
        #endif
        {"too_many_files_open_in_system",       "ENFILE",           std::errc::too_many_files_open_in_system},
        {"too_many_files_open",                 "EMFILE",           std::errc::too_many_files_open},
        {"too_many_links",                      "EMLINK",           std::errc::too_many_links},
        {"too_many_symbolic_link_levels",       "ELOOP",            std::errc::too_many_symbolic_link_levels},
        #if _XSFW_SKIP_CHECK || defined(_GLIBCXX_HAVE_EOVERFLOW)
        {"value_too_large",                     "EOVERFLOW",        std::errc::value_too_large},
        #endif
        {"wrong_protocol_type",                 "EPROTOTYPE",       std::errc::wrong_protocol_type},
    };

    for (const auto& item : list) {
        auto v = xs::out(make_error_code(item.value));
        errc_stash.add_const_sub(item.long_name, v);
        errc_stash.add_const_sub(item.short_name, v);
    }

    Stash future_errc_stash("XS::STL::future_errc", GV_ADD);
    future_errc_stash.add_const_sub("broken_promise",            Simple(int(std::future_errc::broken_promise)));
    future_errc_stash.add_const_sub("future_already_retrieved",  Simple(int(std::future_errc::future_already_retrieved)));
    future_errc_stash.add_const_sub("promise_already_satisfied", Simple(int(std::future_errc::promise_already_satisfied)));
    future_errc_stash.add_const_sub("no_state",                  Simple(int(std::future_errc::no_state)));
    
    Stash stl_stash("XS::STL", GV_ADD);
    stl_stash.add_const_sub("generic_category",  xs::out<const std::error_category*>(&std::generic_category()));
    stl_stash.add_const_sub("system_category",   xs::out<const std::error_category*>(&std::system_category()));
    stl_stash.add_const_sub("future_category",   xs::out<const std::error_category*>(&std::future_category()));
}
