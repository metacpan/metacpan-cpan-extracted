#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <sys/param.h>
#include <sys/resource.h>
#include <sys/sysctl.h>
#if defined(__OpenBSD__)
#include <uvm/uvm_param.h>
#elif defined(__FreeBSD__) || defined(__DragonFly__)
#include <vm/vm_param.h>
#endif

MODULE = Unix::Uptime::BSD::XS PACKAGE = Unix::Uptime::BSD::XS

void
sysctl_kern_boottime()
    INIT:
        int mib[2] = { CTL_KERN, KERN_BOOTTIME };
        struct timeval boottime;
        size_t len = sizeof(boottime);
    PPCODE:
        if (-1 == sysctl(mib, 2, &boottime, &len, NULL, 0)) {
            croak("sysctl: %s", strerror(errno));
        }
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(boottime.tv_sec)));
        PUSHs(sv_2mortal(newSViv(boottime.tv_usec)));

void
sysctl_vm_loadavg()
    INIT:
        int mib[2] = { CTL_VM, VM_LOADAVG };
        struct loadavg load;
        size_t len = sizeof(load);
    PPCODE:
        if (-1 == sysctl(mib, 2, &load, &len, NULL, 0)) {
            croak("sysctl: %s", strerror(errno));
        }
        EXTEND(SP, 4);
        PUSHs(sv_2mortal(newSViv(load.ldavg[0])));
        PUSHs(sv_2mortal(newSViv(load.ldavg[1])));
        PUSHs(sv_2mortal(newSViv(load.ldavg[2])));
        PUSHs(sv_2mortal(newSViv(load.fscale)));

