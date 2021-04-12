#pragma once
#include "inc.h"
#include "error.h"
#include "Handle.h"
#include "AddrInfo.h"
#include <array>
#include <vector>
#include <panda/excepted.h>
#include <panda/net/sockaddr.h>

#undef socketpair

namespace panda { namespace unievent {

excepted<AddrInfo, std::error_code> sync_resolve (backend::Backend*, string_view host, uint16_t port = 0, const AddrInfoHints& = {}, bool use_cache = true);

net::SockAddr broadcast_addr (uint16_t port, const AddrInfoHints& = {});

fd_t   file_dup  (fd_t);
sock_t sock_dup  (sock_t);
sock_t fd2sock   (fd_t);
fd_t   sock2fd   (sock_t);
bool   is_socket (fd_t);

excepted<sock_t, std::error_code> socket      (int domain, int type, int protocol);
excepted<void,   std::error_code> connect     (sock_t sock, const net::SockAddr&);
excepted<void,   std::error_code> bind        (sock_t sock, const net::SockAddr&);
excepted<void,   std::error_code> listen      (sock_t sock, int backlog);
excepted<sock_t, std::error_code> accept      (sock_t srv, net::SockAddr* = nullptr);
excepted<void,   std::error_code> setsockopt  (sock_t sock, int level, int optname, const void* optval, int optlen);
excepted<void,   std::error_code> setblocking (sock_t sock, bool val);
excepted<void,   std::error_code> close       (sock_t sock);

excepted<net::SockAddr, std::error_code> getsockname (sock_t sock);
excepted<net::SockAddr, std::error_code> getpeername (sock_t sock);

struct PairFlags {
    static constexpr int nonblock_pipe = 1;
};

excepted<std::pair<sock_t,sock_t>, std::error_code>
socketpair (int type = SOCK_STREAM, int protocol = PF_UNSPEC, int flags1 = PairFlags::nonblock_pipe, int flags2 = PairFlags::nonblock_pipe);

excepted<std::pair<fd_t,fd_t>, std::error_code>
pipe (int read_flags = PairFlags::nonblock_pipe, int write_flags = PairFlags::nonblock_pipe);

int           getpid           ();
int           getppid          ();
uint64_t      hrtime           ();
uint64_t      get_free_memory  ();
uint64_t      get_total_memory ();

excepted<TimeVal, std::error_code> gettimeofday ();
excepted<string,  std::error_code> hostname     ();
excepted<size_t,  std::error_code> get_rss      ();

char** setup_args (int argc, char** argv);
excepted<string, std::error_code> get_process_title ();
excepted<void,   std::error_code> set_process_title (string_view);

struct InterfaceAddress {
    string        name;
    char          phys_addr[6];
    bool          is_internal;
    net::SockAddr address;
    net::SockAddr netmask;
};

excepted<std::vector<InterfaceAddress>, std::error_code> interface_info ();


struct CpuInfo {
    string model;
    int    speed;
    struct CpuTimes {
        uint64_t user;
        uint64_t nice;
        uint64_t sys;
        uint64_t idle;
        uint64_t irq;
    } cpu_times;
};

excepted<std::vector<CpuInfo>, std::error_code> cpu_info ();


struct ResourceUsage {
   TimeVal  utime;    /* user CPU time used */
   TimeVal  stime;    /* system CPU time used */
   uint64_t maxrss;   /* maximum resident set size */
   uint64_t ixrss;    /* integral shared memory size */
   uint64_t idrss;    /* integral unshared data size */
   uint64_t isrss;    /* integral unshared stack size */
   uint64_t minflt;   /* page reclaims (soft page faults) */
   uint64_t majflt;   /* page faults (hard page faults) */
   uint64_t nswap;    /* swaps */
   uint64_t inblock;  /* block input operations */
   uint64_t oublock;  /* block output operations */
   uint64_t msgsnd;   /* IPC messages sent */
   uint64_t msgrcv;   /* IPC messages received */
   uint64_t nsignals; /* signals received */
   uint64_t nvcsw;    /* voluntary context switches */
   uint64_t nivcsw;   /* involuntary context switches */
};

excepted<ResourceUsage, std::error_code> get_rusage ();

struct UtsName {
    string sysname;
    string release;
    string version;
    string machine;
};

excepted<UtsName, std::error_code> uname ();

struct Wsl {
    enum Version {
        NOT = 0,
        _1,
        _2
    };
};

Wsl::Version is_wsl();


struct RandomRequest;
using RandomRequestSP = iptr<RandomRequest>;

struct RandomRequest : Work, private IWorkSelfListener {
    using random_fn = function<void(string&, const std::error_code&, const RandomRequestSP&)>;

    random_fn cb;

    RandomRequest (const random_fn&, const LoopSP& = Loop::default_loop());

    void start (size_t);

private:
    size_t          _len = 0;
    std::error_code _err;
    string          _result;

    void on_work       () override;
    void on_after_work (const std::error_code&) override;
};

excepted<string, std::error_code> get_random (size_t len);

RandomRequestSP get_random (size_t len, const RandomRequest::random_fn&, const LoopSP& = Loop::default_loop());


const HandleType& guess_type (fd_t);

std::error_code sys_error           (int syserr);
std::error_code last_sys_error      ();
std::error_code last_sys_sock_error ();
std::error_code uvx_error           (int uverr);

}}
