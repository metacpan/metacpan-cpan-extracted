#include <xs/export.h>
#include <xs/net/sockaddr.h>
#include <xs/unievent/util.h>
#include <xs/unievent/Loop.h>
#include <xs/unievent/error.h>
#include <panda/unievent/util.h>

using namespace xs;
using namespace xs::unievent;
using namespace panda::unievent;
using panda::string_view;
using panda::unievent::backend::Backend;


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
        {"AF_INET",          AF_INET         },
        {"AF_INET6",         AF_INET6        },
        {"INET_ADDRSTRLEN",  INET_ADDRSTRLEN },
        {"INET6_ADDRSTRLEN", INET6_ADDRSTRLEN},
        {"PF_INET",          PF_INET         },
        {"PF_INET6",         PF_INET6        },
        {"SOCK_STREAM",      SOCK_STREAM     },
        {"SOCK_DGRAM",       SOCK_DGRAM      }
    });
    xs::exp::autoexport(stash);
    
    xs::add_catch_handler([]() -> Sv {
        try { throw; }
        catch (Error& err) { return xs::out(err.clone()); }
        return nullptr;
    });
}

Backend* default_backend ()

void set_default_backend (Backend* be)


panda::string hostname ()

size_t get_rss ()

uint64_t get_free_memory () {
    RETVAL = get_free_memory();
}

uint64_t get_total_memory () {
    RETVAL = get_total_memory();
}

void interface_info () {
    auto info = interface_info();

    if (GIMME_V != G_ARRAY) {
        mXPUSHs(newSVuv(info.size()));
        XSRETURN(1);
    }

    EXTEND(SP, (int)info.size());
    for (const auto& row : info) {
        auto hash = Hash::create();
        hash.store("name",        Simple(row.name));
        hash.store("phys_addr",   Simple(string_view(row.phys_addr, sizeof(row.phys_addr))));
        hash.store("is_internal", Simple(row.is_internal));
        hash.store("address",     xs::out(row.address));
        hash.store("netmask",     xs::out(row.netmask));
        
        mPUSHs(Ref::create(hash).detach());
    }
}

void cpu_info () {
    auto info = cpu_info();
    
    if (GIMME_V != G_ARRAY) {
        mXPUSHs(newSVuv(info.size()));
        XSRETURN(1);
    }
    
    EXTEND(SP, (int)info.size());
    for (const auto& row : info) {
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
        
        mPUSHs(Ref::create(hash).detach());
    }
}

Hash get_rusage () {
    auto res = get_rusage();
    RETVAL = Hash::create();
    RETVAL.store("utime",    Simple((double)res.utime.sec + (double)res.utime.usec/1000000));
    RETVAL.store("stime",    Simple((double)res.stime.sec + (double)res.stime.usec/1000000));
    RETVAL.store("maxrss",   Simple(res.maxrss));
    RETVAL.store("ixrss",    Simple(res.ixrss));
    RETVAL.store("idrss",    Simple(res.idrss));
    RETVAL.store("isrss",    Simple(res.isrss));
    RETVAL.store("minflt",   Simple(res.minflt));
    RETVAL.store("majflt",   Simple(res.majflt));
    RETVAL.store("nswap",    Simple(res.nswap));
    RETVAL.store("inblock",  Simple(res.inblock));
    RETVAL.store("oublock",  Simple(res.oublock));
    RETVAL.store("msgsnd",   Simple(res.msgsnd));
    RETVAL.store("msgrcv",   Simple(res.msgrcv));
    RETVAL.store("nsignals", Simple(res.nsignals));
    RETVAL.store("nvcsw",    Simple(res.nvcsw));
    RETVAL.store("nivcsw",   Simple(res.nivcsw));
}

string_view guess_type (Sv sv) {
    RETVAL = guess_type(sv2fd(sv)).name;
}



MODULE = UniEvent                PACKAGE = UniEvent::Backend
PROTOTYPES: DISABLE

string_view Backend::name ()



MODULE = UniEvent                PACKAGE = UniEvent::Request
PROTOTYPES: DISABLE

BOOT {
    Stash stash(__PACKAGE__, GV_ADD);
    (void)stash;
}
