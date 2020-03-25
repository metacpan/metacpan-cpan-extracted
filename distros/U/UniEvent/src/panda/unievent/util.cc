#include "util.h"
#include "Tcp.h"
#include "Udp.h"
#include "Pipe.h"
#include "Resolver.h"
#include "Tty.h"
#include "Fs.h"

#include <uv.h>
#include <ostream>

#ifdef _WIN32
    #include "util_win.icc"
#else
    #include "util_unix.icc"
#endif

#ifdef __unix__
    #include <sys/utsname.h>
#endif

using panda::net::SockAddr;

namespace panda { namespace unievent {

AddrInfo sync_resolve (backend::Backend* be, string_view host, uint16_t port, const AddrInfoHints& hints, bool use_cache) {
    auto l = SyncLoop::get(be);
    AddrInfo ai;
    l->resolver()->resolve()->node(string(host))->port(port)->hints(hints)->use_cache(use_cache)->on_resolve([&ai](const AddrInfo& res, const std::error_code& err, const Resolver::RequestSP&) {
        if (err) throw Error(err);
        ai = res;
    })->run();
    l->run();
    return ai;
}

net::SockAddr broadcast_addr (uint16_t port, const AddrInfoHints& hints) {
    if (hints.family == AF_INET6) return SockAddr::Inet6(SockAddr::Inet6::addr_any, port);
    else                          return SockAddr::Inet4(SockAddr::Inet4::addr_any, port);
}

bool is_socket (fd_t fd) {
    return Fs::stat(fd).value().type() == Fs::FileType::SOCKET;
}

excepted<void, std::error_code> connect (sock_t sock, const net::SockAddr& sa) {
    auto status = ::connect(sock, sa.get(), sa.length());
    if (status != 0) return make_unexpected(last_sys_sock_error());
    return {};
}

excepted<void, std::error_code> bind (sock_t sock, const net::SockAddr& sa) {
    auto status = ::bind(sock, sa.get(), sa.length());
    if (status != 0) return make_unexpected(last_sys_sock_error());
    return {};
}

excepted<void, std::error_code> listen (sock_t sock, int backlog) {
    auto status = ::listen(sock, backlog);
    if (status != 0) return make_unexpected(last_sys_sock_error());
    return {};
}

excepted<std::array<sock_t,2>, std::error_code> inet_socketpair (int type, int protocol) {
    std::array<sock_t,2> socks;
    int domain = AF_INET;
    auto rets = socket(domain, type, protocol);
    if (!rets) return make_unexpected(rets.error());
    auto lsock = rets.value();

    auto ret = bind(lsock, net::SockAddr::Inet4::sa_loopback);
    if (!ret) {
        close(lsock).nevermind();
        return make_unexpected(ret.error());
    }

    ret = listen(lsock, 1);
    if (!ret) {
        close(lsock).nevermind();
        return make_unexpected(ret.error());
    }

    auto retsa = getsockname(lsock);
    if (!retsa) {
        close(lsock).nevermind();
        return make_unexpected(retsa.error());
    }
    auto sa = retsa.value();

    rets = socket(domain, type, protocol);
    if (!rets) {
        close(lsock).nevermind();
        return make_unexpected(rets.error());
    }
    auto csock = socks[1] = rets.value();

    ret = setblocking(csock, false);
    if (!ret) {
        close(lsock).nevermind();
        close(csock).nevermind();
        return make_unexpected(ret.error());
    }

    ret = connect(csock, sa);
    if (!ret && ret.error() != std::errc::resource_unavailable_try_again) {
        close(lsock).nevermind();
        close(csock).nevermind();
        return make_unexpected(ret.error());
    }

    rets = accept(lsock);
    if (!rets) {
        close(lsock).nevermind();
        close(csock).nevermind();
        return make_unexpected(ret.error());
    }
    auto ssock = socks[0] = rets.value();

    ret = close(lsock);
    if (!ret) {
        close(csock).nevermind();
        close(ssock).nevermind();
        return make_unexpected(ret.error());
    }

    ret = setblocking(csock, true);
    if (!ret) {
        close(csock).nevermind();
        close(ssock).nevermind();
        return make_unexpected(ret.error());
    }

    return socks;
}

int getpid  () { return uv_os_getpid(); }
int getppid () { return uv_os_getppid(); }

TimeVal gettimeofday () {
    TimeVal ret;
    uv_timeval64_t tv;
    auto err = uv_gettimeofday(&tv);
    if (err) throw Error(uvx_error(err));
    ret.sec  = tv.tv_sec;
    ret.usec = tv.tv_usec;
    return ret;
}

string hostname () {
    string ret(20);
    size_t len = ret.capacity();
    int err = uv_os_gethostname(ret.buf(), &len);
    if (err) {
        if (err != UV_ENOBUFS) throw Error(uvx_error(err));
        ret.reserve(len);
        err = uv_os_gethostname(ret.buf(), &len);
        if (err) throw Error(uvx_error(err));
    }
    ret.length(len);
    return ret;
}

size_t get_rss () {
    size_t rss;
    int err = uv_resident_set_memory(&rss);
    if (err) throw Error(uvx_error(err));
    return rss;
}

uint64_t get_free_memory  () {
    return uv_get_free_memory();
}

uint64_t get_total_memory () {
    return uv_get_total_memory();
}

std::vector<InterfaceAddress> interface_info () {
    uv_interface_address_t* uvlist;
    int cnt;
    int err = uv_interface_addresses(&uvlist, &cnt);
    if (err) throw Error(uvx_error(err));

    std::vector<InterfaceAddress> ret;
    ret.reserve(cnt);
    for (int i = 0; i < cnt; ++i) {
        auto& uvrow = uvlist[i];
        InterfaceAddress row;
        row.name = uvrow.name;
        memcpy(row.phys_addr, uvrow.phys_addr, sizeof(uvrow.phys_addr));
        row.is_internal = uvrow.is_internal;
        row.address = SockAddr((sockaddr*)&uvrow.address);
        row.netmask = SockAddr((sockaddr*)&uvrow.netmask);
        ret.push_back(row);
    }

    uv_free_interface_addresses(uvlist, cnt);

    return ret;
}

std::vector<CpuInfo> cpu_info () {
    uv_cpu_info_t* uvlist;
    int cnt;
    int err = uv_cpu_info(&uvlist, &cnt);
    if (err) throw Error(uvx_error(err));

    std::vector<CpuInfo> ret;
    ret.reserve(cnt);
    for (int i = 0; i < cnt; ++i) {
        auto& uvrow = uvlist[i];
        CpuInfo row;
        row.model = uvrow.model;
        row.speed = uvrow.speed;
        row.cpu_times.user = uvrow.cpu_times.user;
        row.cpu_times.nice = uvrow.cpu_times.nice;
        row.cpu_times.sys  = uvrow.cpu_times.sys;
        row.cpu_times.idle = uvrow.cpu_times.idle;
        row.cpu_times.irq  = uvrow.cpu_times.irq;
        ret.push_back(row);
    }

    uv_free_cpu_info(uvlist, cnt);

    return ret;
}

ResourceUsage get_rusage () {
    uv_rusage_t d;
    int err = uv_getrusage(&d);
    if (err) throw Error(uvx_error(err));

    ResourceUsage ret;
    ret.utime.sec  = d.ru_utime.tv_sec;
    ret.utime.usec = d.ru_utime.tv_usec;
    ret.stime.sec  = d.ru_stime.tv_sec;
    ret.stime.usec = d.ru_stime.tv_usec;
    ret.maxrss     = d.ru_maxrss;
    ret.ixrss      = d.ru_ixrss;
    ret.idrss      = d.ru_idrss;
    ret.isrss      = d.ru_isrss;
    ret.minflt     = d.ru_minflt;
    ret.majflt     = d.ru_majflt;
    ret.nswap      = d.ru_nswap;
    ret.inblock    = d.ru_inblock;
    ret.oublock    = d.ru_oublock;
    ret.msgsnd     = d.ru_msgsnd;
    ret.msgrcv     = d.ru_msgrcv;
    ret.nsignals   = d.ru_nsignals;
    ret.nvcsw      = d.ru_nvcsw;
    ret.nivcsw     = d.ru_nivcsw;

    return ret;
}

const HandleType& guess_type (fd_t file) {
    auto uvt = uv_guess_handle(file);
    switch (uvt) {
        case UV_TTY       : return Tty::TYPE;
        case UV_FILE      : return Fs::TYPE;
        case UV_NAMED_PIPE: return Pipe::TYPE;
        case UV_UDP       : return Udp::TYPE;
        case UV_TCP       : return Tcp::TYPE;
        default           : return Handle::UNKNOWN_TYPE;
    }
}

std::error_code uvx_error (int uverr) {
    assert(uverr);
    switch (uverr) {
        case UV_E2BIG          : return make_error_code(std::errc::argument_list_too_long);
        case UV_EACCES         : return make_error_code(std::errc::permission_denied);
        case UV_EADDRINUSE     : return make_error_code(std::errc::address_in_use);
        case UV_EADDRNOTAVAIL  : return make_error_code(std::errc::address_not_available);
        case UV_EAFNOSUPPORT   : return make_error_code(std::errc::address_family_not_supported);
        case UV_EAGAIN         : return make_error_code(std::errc::resource_unavailable_try_again);
        case UV_EAI_ADDRFAMILY : return make_error_code(errc::ai_address_family_not_supported);
        case UV_EAI_AGAIN      : return make_error_code(errc::ai_temporary_failure);
        case UV_EAI_BADFLAGS   : return make_error_code(errc::ai_bad_flags);
        case UV_EAI_BADHINTS   : return make_error_code(errc::ai_bad_hints);
        case UV_EAI_CANCELED   : return make_error_code(errc::ai_request_canceled);
        case UV_EAI_FAIL       : return make_error_code(errc::ai_permanent_failure);
        case UV_EAI_FAMILY     : return make_error_code(errc::ai_family_not_supported);
        case UV_EAI_MEMORY     : return make_error_code(errc::ai_out_of_memory);
        case UV_EAI_NODATA     : return make_error_code(errc::ai_no_address);
        case UV_EAI_NONAME     : return make_error_code(errc::ai_unknown_node_or_service);
        case UV_EAI_OVERFLOW   : return make_error_code(errc::ai_argument_buffer_overflow);
        case UV_EAI_PROTOCOL   : return make_error_code(errc::ai_resolved_protocol_unknown);
        case UV_EAI_SERVICE    : return make_error_code(errc::ai_service_not_available_for_socket_type);
        case UV_EAI_SOCKTYPE   : return make_error_code(errc::ai_socket_type_not_supported);
        case UV_EALREADY       : return make_error_code(std::errc::connection_already_in_progress);
        case UV_EBADF          : return make_error_code(std::errc::bad_file_descriptor);
        case UV_EBUSY          : return make_error_code(std::errc::device_or_resource_busy);
        case UV_ECANCELED      : return make_error_code(std::errc::operation_canceled);
        case UV_ECHARSET       : return make_error_code(errc::invalid_unicode_character);
        case UV_ECONNABORTED   : return make_error_code(std::errc::connection_aborted);
        case UV_ECONNREFUSED   : return make_error_code(std::errc::connection_refused);
        case UV_ECONNRESET     : return make_error_code(std::errc::connection_reset);
        case UV_EDESTADDRREQ   : return make_error_code(std::errc::destination_address_required);
        case UV_EEXIST         : return make_error_code(std::errc::file_exists);
        case UV_EFAULT         : return make_error_code(std::errc::bad_address);
        case UV_EFBIG          : return make_error_code(std::errc::file_too_large);
        case UV_EHOSTUNREACH   : return make_error_code(std::errc::host_unreachable);
        case UV_EINTR          : return make_error_code(std::errc::interrupted);
        case UV_EINVAL         : return make_error_code(std::errc::invalid_argument);
        case UV_EIO            : return make_error_code(std::errc::io_error);
        case UV_EISCONN        : return make_error_code(std::errc::already_connected);
        case UV_EISDIR         : return make_error_code(std::errc::is_a_directory);
        case UV_ELOOP          : return make_error_code(std::errc::too_many_symbolic_link_levels);
        case UV_EMFILE         : return make_error_code(std::errc::too_many_files_open);
        case UV_EMSGSIZE       : return make_error_code(std::errc::message_size);
        case UV_ENAMETOOLONG   : return make_error_code(std::errc::filename_too_long);
        case UV_ENETDOWN       : return make_error_code(std::errc::network_down);
        case UV_ENETUNREACH    : return make_error_code(std::errc::network_unreachable);
        case UV_ENFILE         : return make_error_code(std::errc::too_many_files_open_in_system);
        case UV_ENOBUFS        : return make_error_code(std::errc::no_buffer_space);
        case UV_ENODEV         : return make_error_code(std::errc::no_such_device);
        case UV_ENOENT         : return make_error_code(std::errc::no_such_file_or_directory);
        case UV_ENOMEM         : return make_error_code(std::errc::not_enough_memory);
        case UV_ENONET         : return make_error_code(errc::not_on_network);
        case UV_ENOPROTOOPT    : return make_error_code(std::errc::no_protocol_option);
        case UV_ENOSPC         : return make_error_code(std::errc::no_space_on_device);
        case UV_ENOSYS         : return make_error_code(std::errc::function_not_supported);
        case UV_ENOTCONN       : return make_error_code(std::errc::not_connected);
        case UV_ENOTDIR        : return make_error_code(std::errc::not_a_directory);
        case UV_ENOTEMPTY      : return make_error_code(std::errc::directory_not_empty);
        case UV_ENOTSOCK       : return make_error_code(std::errc::not_a_socket);
        case UV_ENOTSUP        : return make_error_code(std::errc::not_supported);
        case UV_EPERM          : return make_error_code(std::errc::operation_not_permitted);
        case UV_EPIPE          : return make_error_code(std::errc::broken_pipe);
        case UV_EPROTO         : return make_error_code(std::errc::protocol_error);
        case UV_EPROTONOSUPPORT: return make_error_code(std::errc::protocol_not_supported);
        case UV_EPROTOTYPE     : return make_error_code(std::errc::wrong_protocol_type);
        case UV_ERANGE         : return make_error_code(std::errc::result_out_of_range);
        case UV_EROFS          : return make_error_code(std::errc::read_only_file_system);
        case UV_ESHUTDOWN      : return make_error_code(errc::transport_endpoint_shutdown);
        case UV_ESPIPE         : return make_error_code(std::errc::invalid_seek);
        case UV_ESRCH          : return make_error_code(std::errc::no_such_process);
        case UV_ETIMEDOUT      : return make_error_code(std::errc::timed_out);
        #if !defined(_WIN32) || defined(_GLIBCXX_HAVE_ETXTBSY)
        case UV_ETXTBSY        : return make_error_code(std::errc::text_file_busy);
        #endif
        case UV_EXDEV          : return make_error_code(std::errc::cross_device_link);
        case UV_UNKNOWN        : return make_error_code(errc::unknown_error);
        case UV_ENXIO          : return make_error_code(std::errc::no_such_device_or_address);
        case UV_EMLINK         : return make_error_code(std::errc::too_many_links);
        case UV_EHOSTDOWN      : return make_error_code(errc::host_down);
        case UV_EREMOTEIO      : return make_error_code(errc::remote_io);
        case UV_ENOTTY         : return make_error_code(std::errc::inappropriate_io_control_operation);
        default                : return make_error_code(errc::unknown_error);
    }
}

std::ostream& operator<< (std::ostream& os, const TimeVal&  v) { return os << v.get(); }
std::ostream& operator<< (std::ostream& os, const TimeSpec& v) { return os << v.get(); }

Wsl::Version is_wsl() {
#ifdef __unix__
    utsname buf;
    memset(&buf, 0, sizeof buf);
    int ret = uname(&buf);
    if (ret == 0) {
        if (strstr(buf.release, "Microsoft"))
            return Wsl::_1;
        else if (strstr(buf.release, "microsoft"))
            return Wsl::_2;
    }
#endif
    return Wsl::NOT;
}

}}
