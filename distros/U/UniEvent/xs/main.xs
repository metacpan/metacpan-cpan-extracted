#include <xs/export.h>
#include <xs/net/sockaddr.h>
#include <xs/unievent/util.h>
#include <xs/unievent/Loop.h>
#include <xs/unievent/error.h>
#include <xs/typemap/expected.h>
#include <panda/unievent/util.h>

using namespace xs;
using namespace xs::unievent;
using namespace panda::unievent;
using panda::string_view;
using panda::unievent::backend::Backend;

namespace xs {
    template <> struct Typemap<InterfaceAddress> : TypemapBase<InterfaceAddress> {
        static Sv out (const InterfaceAddress& row, Sv = {}) {
            auto hash = Hash::create();
            hash.store("name",        Simple(row.name));
            hash.store("phys_addr",   Simple(string_view(row.phys_addr, sizeof(row.phys_addr))));
            hash.store("is_internal", Simple(row.is_internal));
            hash.store("address",     xs::out(row.address));
            hash.store("netmask",     xs::out(row.netmask));
            return Ref::create(hash);
        }
    };
    
    template <> struct Typemap<CpuInfo> : TypemapBase<CpuInfo> {
        static Sv out (const CpuInfo& row, Sv = {}) {
            auto hash = Hash::create();
            hash.store("model", Simple(row.model));
            hash.store("speed", Simple(row.speed));

            auto cpu_times = Hash::create();
            cpu_times.store("user", Simple(row.cpu_times.user));
            cpu_times.store("nice", Simple(row.cpu_times.nice));
            cpu_times.store("sys",  Simple(row.cpu_times.sys));
            cpu_times.store("idle", Simple(row.cpu_times.idle));
            cpu_times.store("irq",  Simple(row.cpu_times.irq));
            hash.store("cpu_times", Ref::create(cpu_times));

            return Ref::create(hash);
        }
    };
    
    template <> struct Typemap<ResourceUsage> : TypemapBase<ResourceUsage> {
        static Sv out (const ResourceUsage& res, Sv = {}) {
            auto ret = Hash::create();
            ret.store("utime",    Simple((double)res.utime.sec + (double)res.utime.usec/1000000));
            ret.store("stime",    Simple((double)res.stime.sec + (double)res.stime.usec/1000000));
            ret.store("maxrss",   Simple(res.maxrss));
            ret.store("ixrss",    Simple(res.ixrss));
            ret.store("idrss",    Simple(res.idrss));
            ret.store("isrss",    Simple(res.isrss));
            ret.store("minflt",   Simple(res.minflt));
            ret.store("majflt",   Simple(res.majflt));
            ret.store("nswap",    Simple(res.nswap));
            ret.store("inblock",  Simple(res.inblock));
            ret.store("oublock",  Simple(res.oublock));
            ret.store("msgsnd",   Simple(res.msgsnd));
            ret.store("msgrcv",   Simple(res.msgrcv));
            ret.store("nsignals", Simple(res.nsignals));
            ret.store("nvcsw",    Simple(res.nvcsw));
            ret.store("nivcsw",   Simple(res.nivcsw));
            return Ref::create(ret);
        }
    };
    
    template <> struct Typemap<UtsName> : TypemapBase<UtsName> {
        static Sv out (const UtsName& v, Sv = {}) {
            auto ret = Hash::create();
            ret.store("sysname", Simple(v.sysname));
            ret.store("release", Simple(v.release));
            ret.store("version", Simple(v.version));
            ret.store("machine", Simple(v.machine));
            return Ref::create(ret);
        }
    };
}


MODULE = UniEvent                PACKAGE = UniEvent
PROTOTYPES: DISABLE

BOOT {
    XS_BOOT(UniEvent__Error);
    XS_BOOT(UniEvent__Loop);
    XS_BOOT(UniEvent__Handle);
    XS_BOOT(UniEvent__Prepare);
    XS_BOOT(UniEvent__Check);
    XS_BOOT(UniEvent__Idle);
    XS_BOOT(UniEvent__Timer);
    XS_BOOT(UniEvent__Signal);
    XS_BOOT(UniEvent__Poll);
    XS_BOOT(UniEvent__Udp);
    XS_BOOT(UniEvent__Stream);
    XS_BOOT(UniEvent__Streamer);
    XS_BOOT(UniEvent__Pipe);
    XS_BOOT(UniEvent__Test);
    XS_BOOT(UniEvent__Tcp);
    XS_BOOT(UniEvent__Tty);
    XS_BOOT(UniEvent__Fs);
    XS_BOOT(UniEvent__FsPoll);
    XS_BOOT(UniEvent__FsEvent);
    XS_BOOT(UniEvent__Resolver);
    XS_BOOT(UniEvent__Backend__UV);

    Stash stash(__MODULE__);

    xs::exp::create_constants(stash, {
        {"AF_INET",          AF_INET          },
        {"AF_INET6",         AF_INET6         },
        {"AF_UNSPEC",        AF_UNSPEC        },
        {"INET_ADDRSTRLEN",  INET_ADDRSTRLEN  },
        {"INET6_ADDRSTRLEN", INET6_ADDRSTRLEN },
        {"PF_INET",          PF_INET          },
        {"PF_INET6",         PF_INET6         },
        {"PF_UNSPEC",        PF_UNSPEC        },
        {"SOCK_STREAM",      SOCK_STREAM      },
        {"SOCK_DGRAM",       SOCK_DGRAM       },
    });
    xs::exp::autoexport(stash);

    xs::add_catch_handler([]() -> Sv {
        try { throw; }
        catch (ErrorCode& err) { return xs::out(err); }
        catch (Error& err) { return xs::out(err.clone()); }
        return nullptr;
    });
}

Backend* default_backend ()

void set_default_backend (Backend* be)


void hostname () {
    XSRETURN_EXPECTED(hostname());
}

void uname () {
    XSRETURN_EXPECTED(uname());
}

void get_rss () {
    XSRETURN_EXPECTED(get_rss());
}

uint64_t get_free_memory () {
    RETVAL = get_free_memory();
}

uint64_t get_total_memory () {
    RETVAL = get_total_memory();
}

void interface_info () {
    XSRETURN_EXPECTED(interface_info());
}

void cpu_info () {
    XSRETURN_EXPECTED(cpu_info());
}

void get_rusage () {
    XSRETURN_EXPECTED(get_rusage());
}

string_view guess_type (Sv sv) {
    RETVAL = guess_type(sv2fd(sv)).name;
}

INCLUDE: Backend.xsi

INCLUDE: Request.xsi

INCLUDE: Work.xsi

INCLUDE: random.xsi
