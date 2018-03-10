#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "string.h"
#include "ppport.h"

#include "p5uv_constants.h"
#include "uv.h"

#define P5LUV_DOUBLETIME(TV) ((double)(TV).tv_sec + 1e-6*(TV).tv_usec)

MODULE = UV::Util       PACKAGE = UV::Util   PREFIX = luv_

PROTOTYPES: DISABLE

BOOT:
{
    constants_export_uv_util(aTHX);
}


SV * luv_cpu_info()
    INIT:
        AV * results;
        int i, count, err;
        uv_cpu_info_t* cpus;
    CODE:
        err = uv_cpu_info(&cpus, &count);
        if (err != 0) {
            croak("Error getting CPU info (%i): %s", err, uv_strerror(err));
        }

        results = newAV();
        for (i = 0; i < count; i++) {
            HV *info, *time;

            info = newHV();
            hv_stores(info, "model", newSVpvn(cpus[i].model, strlen(cpus[i].model)));
            hv_stores(info, "speed", newSVuv((size_t) cpus[i].speed));

            time = newHV();
            hv_stores(time, "sys", newSVuv((size_t) cpus[i].cpu_times.sys));
            hv_stores(time, "user", newSVuv((size_t) cpus[i].cpu_times.user));
            hv_stores(time, "idle", newSVuv((size_t) cpus[i].cpu_times.idle));
            hv_stores(time, "irq", newSVuv((size_t) cpus[i].cpu_times.irq));
            hv_stores(time, "nice", newSVuv((size_t) cpus[i].cpu_times.nice));

            /* add time as a href within info */
            hv_stores(info, "cpu_times", newRV_noinc((SV *)time));

            /* push info href onto results array */
            av_push(results, newRV_noinc((SV *)info));
        }
        uv_free_cpu_info(cpus, count);
        RETVAL = newRV_noinc((SV *)results);
    OUTPUT:
    RETVAL

size_t luv_get_free_memory()
    CODE:
        RETVAL = uv_get_free_memory();
    OUTPUT:
    RETVAL

size_t luv_get_total_memory()
    CODE:
        RETVAL = uv_get_total_memory();
    OUTPUT:
    RETVAL

SV * luv_getrusage()
    INIT:
        int err;
        uv_rusage_t ru;
        HV * result;
    CODE:
        err = uv_getrusage(&ru);
        if (err < 0) {
            croak("Error getting rusage (%i): %s", err, uv_strerror(err));
        }

        result = newHV();
        hv_stores(result, "ru_utime", newSVnv(P5LUV_DOUBLETIME(ru.ru_utime)));
        hv_stores(result, "ru_stime", newSVnv(P5LUV_DOUBLETIME(ru.ru_stime)));
        hv_stores(result, "ru_maxrss", newSVuv((size_t) ru.ru_maxrss));
        hv_stores(result, "ru_ixrss", newSVuv((size_t) ru.ru_ixrss));
        hv_stores(result, "ru_idrss", newSVuv((size_t) ru.ru_idrss));
        hv_stores(result, "ru_isrss", newSVuv((size_t) ru.ru_isrss));
        hv_stores(result, "ru_minflt", newSVuv((size_t) ru.ru_minflt));
        hv_stores(result, "ru_majflt", newSVuv((size_t) ru.ru_majflt));
        hv_stores(result, "ru_nswap", newSVuv((size_t) ru.ru_nswap));
        hv_stores(result, "ru_inblock", newSVuv((size_t) ru.ru_inblock));
        hv_stores(result, "ru_oublock", newSVuv((size_t) ru.ru_oublock));
        hv_stores(result, "ru_msgsnd", newSVuv((size_t) ru.ru_msgsnd));
        hv_stores(result, "ru_msgrcv", newSVuv((size_t) ru.ru_msgrcv));
        hv_stores(result, "ru_nsignals", newSVuv((size_t) ru.ru_nsignals));
        hv_stores(result, "ru_nvcsw", newSVuv((size_t) ru.ru_nvcsw));
        hv_stores(result, "ru_nivcsw", newSVuv((size_t) ru.ru_nivcsw));

        RETVAL = newRV_noinc((SV *)result);
    OUTPUT:
    RETVAL

int luv_guess_handle_type(FILE *fh)
    INIT:
        int fn;
    CODE:
        if (!fh) {
            croak("A file handle is required");
        }
        fn = fileno(fh);
        if (fn == -1) {
            croak("Expected a file handle");
        }
        RETVAL = (int)(long) uv_guess_handle(fn);
    OUTPUT:
    RETVAL

size_t luv_hrtime()
    CODE:
        RETVAL = uv_hrtime();
    OUTPUT:
    RETVAL

SV * luv_interface_addresses()
    INIT:
        static char buf[INET6_ADDRSTRLEN+1];
        AV * results;
        uv_interface_address_t* interfaces;
        int i, count, err;
    CODE:
        err = uv_interface_addresses(&interfaces, &count);
        if (err != 0) {
            croak("Error getting interface addresses (%i): %s", err, uv_strerror(err));
        }

        results = newAV();
        for (i = 0; i < count; i++) {
            HV *info;
            info = newHV();

            hv_stores(info, "name", newSVpvn(interfaces[i].name, strlen(interfaces[i].name)));
            hv_stores(info, "is_internal", newSVnv(interfaces[i].is_internal));

            /* IP info */
            if (interfaces[i].address.address4.sin_family == AF_INET) {
                uv_ip4_name(&interfaces[i].address.address4, buf, sizeof(buf));
            } else if (interfaces[i].address.address4.sin_family == AF_INET6) {
                uv_ip6_name(&interfaces[i].address.address6, buf, sizeof(buf));
            }
            hv_stores(info, "address", newSVpvn(buf, strlen(buf)));

            /* Netmask Info */
            if (interfaces[i].netmask.netmask4.sin_family == AF_INET) {
                uv_ip4_name(&interfaces[i].netmask.netmask4, buf, sizeof(buf));
            } else if (interfaces[i].netmask.netmask4.sin_family == AF_INET6) {
                uv_ip6_name(&interfaces[i].netmask.netmask6, buf, sizeof(buf));
            }
            hv_stores(info, "netmask", newSVpvn(buf, strlen(buf)));

            sprintf(buf, "%02x:%02x:%02x:%02x:%02x:%02x",
                        (unsigned char)interfaces[i].phys_addr[0],
                        (unsigned char)interfaces[i].phys_addr[1],
                        (unsigned char)interfaces[i].phys_addr[2],
                        (unsigned char)interfaces[i].phys_addr[3],
                        (unsigned char)interfaces[i].phys_addr[4],
                        (unsigned char)interfaces[i].phys_addr[5]);
            hv_stores(info, "mac", newSVpvn(buf, strlen(buf)));

            av_push(results, newRV_noinc((SV *)info));
        }
        uv_free_interface_addresses(interfaces, count);
        RETVAL = newRV_noinc((SV *)results);
    OUTPUT:
    RETVAL

SV * luv_loadavg()
    INIT:
        AV * results;
        double avg[3];
        size_t i;
    CODE:
        uv_loadavg(avg);
        results = newAV();
        for (i = 0; i < 3; i++) {
            av_push(results, newSVnv(avg[i]));
        }
        RETVAL = newRV_noinc((SV *)results);
    OUTPUT:
    RETVAL

size_t luv_resident_set_memory()
    INIT:
        size_t rss;
        int err;
    CODE:
        err = uv_resident_set_memory(&rss);
        if (err==0) {
            RETVAL=rss;
        }
        else {
            croak("Error getting RSS (%i): %s", err, uv_strerror(err));
        }
    OUTPUT:
    RETVAL

double luv_uptime()
    INIT:
        double uptime;
        int err;
    CODE:
        err = uv_uptime(&uptime);
        if (err==0) {
            RETVAL=uptime;
        }
        else {
            croak("Error getting uptime (%i): %s", err, uv_strerror(err));
        }
    OUTPUT:
    RETVAL

const char * luv_version()
    CODE:
        RETVAL = uv_version_string();
    OUTPUT:
    RETVAL
