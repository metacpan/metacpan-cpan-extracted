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

using panda::net::SockAddr;

namespace panda { namespace unievent {

excepted<AddrInfo, std::error_code> sync_resolve (backend::Backend* be, string_view host, uint16_t port, const AddrInfoHints& hints, bool use_cache) {
    auto l = SyncLoop::get(be);
    AddrInfo ai;
    std::error_code error;
    l->resolver()->resolve()->node(string(host))->port(port)->hints(hints)->use_cache(use_cache)->on_resolve([&ai, &error](const AddrInfo& res, const std::error_code& err, const Resolver::RequestSP&) {
        if (err) error = err;
        else     ai = res;
    })->run();
    l->run();

    if (error) return make_unexpected(error);
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

excepted<std::pair<sock_t,sock_t>, std::error_code> socketpair (int type, int protocol, int flags1, int flags2) {
    sock_t fds[2];
    int uv_flags1 = 0, uv_flags2 = 0;
    if (flags1 & PairFlags::nonblock_pipe) uv_flags1 |= UV_NONBLOCK_PIPE;
    if (flags2 & PairFlags::nonblock_pipe) uv_flags2 |= UV_NONBLOCK_PIPE;
    auto err = uv_socketpair(type, protocol, fds, uv_flags1, uv_flags2);
    if (err) return make_unexpected(uvx_error(err));
    return std::pair<sock_t,sock_t>{fds[0], fds[1]};
}

excepted<std::pair<fd_t,fd_t>, std::error_code> pipe (int read_flags, int write_flags) {
    fd_t fds[2];
    int uv_read_flags = 0, uv_write_flags = 0;
    if (read_flags & PairFlags::nonblock_pipe) uv_read_flags |= UV_NONBLOCK_PIPE;
    if (write_flags & PairFlags::nonblock_pipe) uv_write_flags |= UV_NONBLOCK_PIPE;
    auto err = uv_pipe(fds, uv_read_flags, uv_write_flags);
    if (err) return make_unexpected(uvx_error(err));
    return std::pair<fd_t,fd_t>{fds[0], fds[1]};
}

int getpid  () { return uv_os_getpid(); }
int getppid () { return uv_os_getppid(); }

uint64_t hrtime () {
    return uv_hrtime();
}

excepted<TimeVal, std::error_code> gettimeofday () {
    TimeVal ret;
    uv_timeval64_t tv;
    auto err = uv_gettimeofday(&tv);
    if (err) return make_unexpected(uvx_error(err));
    ret.sec  = tv.tv_sec;
    ret.usec = tv.tv_usec;
    return ret;
}

excepted<string, std::error_code> hostname () {
    string ret(20);
    size_t len = ret.capacity();
    int err = uv_os_gethostname(ret.buf(), &len);
    if (err) {
        if (err != UV_ENOBUFS) return make_unexpected(uvx_error(err));
        ret.reserve(len);
        err = uv_os_gethostname(ret.buf(), &len);
        if (err) return make_unexpected(uvx_error(err));
    }
    ret.length(len);
    return ret;
}

excepted<size_t, std::error_code> get_rss () {
    size_t rss;
    int err = uv_resident_set_memory(&rss);
    if (err) return make_unexpected(uvx_error(err));
    return rss;
}

uint64_t get_free_memory  () {
    return uv_get_free_memory();
}

uint64_t get_total_memory () {
    return uv_get_total_memory();
}

excepted<std::vector<InterfaceAddress>, std::error_code> interface_info () {
    uv_interface_address_t* uvlist;
    int cnt;
    int err = uv_interface_addresses(&uvlist, &cnt);
    if (err) return make_unexpected(uvx_error(err));

    std::vector<InterfaceAddress> ret;
    ret.reserve(cnt);
    for (int i = 0; i < cnt; ++i) {
        auto& uvrow = uvlist[i];
        InterfaceAddress row;
        row.name = uvrow.name;
        memcpy(row.phys_addr, uvrow.phys_addr, sizeof(uvrow.phys_addr));
        row.is_internal = uvrow.is_internal;
        const constexpr size_t addr_size = sizeof(uvrow.address);
        row.address = SockAddr((sockaddr*)&uvrow.address, addr_size);
        row.netmask = SockAddr((sockaddr*)&uvrow.netmask, addr_size);
        ret.push_back(row);
    }

    uv_free_interface_addresses(uvlist, cnt);

    return ret;
}

excepted<std::vector<CpuInfo>, std::error_code> cpu_info () {
    uv_cpu_info_t* uvlist;
    int cnt;
    int err = uv_cpu_info(&uvlist, &cnt);
    if (err) return make_unexpected(uvx_error(err));

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

excepted<ResourceUsage, std::error_code> get_rusage () {
    uv_rusage_t d;
    int err = uv_getrusage(&d);
    if (err) return make_unexpected(uvx_error(err));

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

excepted<UtsName, std::error_code> uname () {
    uv_utsname_t buf;
    auto err = uv_os_uname(&buf);
    if (err) return make_unexpected(uvx_error(err));
    return UtsName{
        string((char*)buf.sysname),
        string((char*)buf.release),
        string((char*)buf.version),
        string((char*)buf.machine)
    };
}

Wsl::Version is_wsl() {
    #ifdef __unix__
    auto ret = uname();
    if (ret) {
        auto info = ret.value();
        if      (info.release.find("Microsoft") != string::npos) return Wsl::_1;
        else if (info.release.find("microsoft") != string::npos) return Wsl::_2;
    }
    #endif
    return Wsl::NOT;
}

excepted<string, std::error_code> get_random (size_t len) {
    string ret(len);
    auto err = uv_random(nullptr, nullptr, ret.buf(), len, 0, nullptr);
    if (err) return make_unexpected(uvx_error(err));
    ret.length(len);
    return ret;
}

RandomRequestSP get_random (size_t len, const RandomRequest::random_fn& cb, const LoopSP& loop) {
    RandomRequestSP req = new RandomRequest(cb, loop);
    req->start(len);
    return req;
}

RandomRequest::RandomRequest (const random_fn& cb, const LoopSP& loop) : Work(loop), cb(cb) {
    event_listener(this);
}

void RandomRequest::on_work () {
    auto res = get_random(_len);
    if (res) _result = res.value();
    else     _err    = res.error();
}

void RandomRequest::on_after_work (const std::error_code& err) {
    cb(_result, err ? err : _err, this);
}

void RandomRequest::start (size_t len) {
    _len = len;
    queue();
}

char** setup_args (int argc, char** argv) {
    return uv_setup_args(argc, argv);
}

excepted<string, std::error_code> get_process_title () {
    for (auto i : {256, 1024, 4096}) {
        string ret(i);
        auto err = uv_get_process_title(ret.buf(), i);
        if (!err) return ret;
        if (err != UV_ENOBUFS) return make_unexpected(uvx_error(err));
    }
    return ""; // too long or setup_args() hasn't been called
}

excepted<void, std::error_code> set_process_title (string_view title) {
    auto err = uv_set_process_title(string(title).c_str());
    if (err) return make_unexpected(uvx_error(err));
    return {};
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

}}
