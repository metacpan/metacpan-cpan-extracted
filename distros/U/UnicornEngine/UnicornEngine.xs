#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "perl_math_int64.h"

#include <unicorn/unicorn.h>

#include "const-c.inc"

typedef struct uc_perl_t {
    void *perl; /* context */
    void *parent; /* parent object */
    uc_engine *engine;
} uc_perl_t;

MODULE = UnicornEngine		PACKAGE = UnicornEngine		

INCLUDE: const-xs.inc

BOOT:
    PERL_MATH_INT64_LOAD_OR_CROAK;

unsigned int
is_arch_supported(arch)
    uc_arch arch
    CODE:
        RETVAL = (uc_arch_supported(arch) ? 1 : 0);
    OUTPUT:
        RETVAL

SV *
version()
    PREINIT:
        unsigned int major = 0, minor = 0;
        unsigned int ver = 0;
        char *verstr = NULL;
        const size_t verstr_len = 32 * sizeof(unsigned char);
    CODE:
        ver = uc_version(&major, &minor);
        if (ver == UC_MAKE_VERSION(UC_API_MAJOR, UC_API_MINOR)) {
            verstr = calloc((size_t)verstr_len, 1);
            if (verstr) {
                snprintf(verstr, verstr_len, "%u.%u", major, minor);
                /* this is a NULL terminated string */
                RETVAL = newSVpv(verstr, 0);
                free(verstr);
            } else {
                Perl_croak(aTHX_ "Out of memory for allocating string for %zu bytes\n",
                            verstr_len);
                XSRETURN_UNDEF;
            }
        } else {
            Perl_croak(aTHX_ "Linked version of Unicorn Engine has version %u.%u and compiled version is %u.%u\n",
                        major, minor, UC_API_MAJOR, UC_API_MINOR);
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL


uc_perl_t *
uc_perl_new(parent, arch, mode)
    SV *parent
    uc_arch arch
    uc_mode mode
    PREINIT:
        uc_engine *engine = NULL;
        uc_err err = UC_ERR_OK;
    CODE:
        Newxz(RETVAL, 1, uc_perl_t);
        if (RETVAL) {
            RETVAL->perl = Perl_get_context();
            err = uc_open(arch, mode, &engine);
            if (err == UC_ERR_OK) {
                RETVAL->engine = engine;
                RETVAL->parent = (void *)SvREFCNT_inc(parent);
            } else {
                RETVAL->engine = NULL;
                RETVAL->parent = NULL;
                warn("Error in creating uc_engine. Error: %s", uc_strerror(err));
                Safefree(RETVAL);
                XSRETURN_UNDEF;
            }
        } else {
            Perl_croak(aTHX_ "Out of memory allocating uc_perl_t object\n");
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

void
uc_perl_DESTROY(obj)
    uc_perl_t *obj
    CODE:
        if (obj) {
            SV *parent = obj->parent;
            SvREFCNT_dec(parent);
            if (obj->engine) {
                uc_err err = uc_close(obj->engine);
                if (err != UC_ERR_OK) {
                    warn("Error in creating uc_engine. Error: %s", uc_strerror(err));
                }
                obj->engine = NULL;
            }
            Safefree(obj);
        }


size_t
uc_perl_query(obj,qtype)
    uc_perl_t *obj
    uc_query_type qtype
    PREINIT:
        size_t result = 0;
    CODE:
        if (obj && obj->engine) {
            uc_err err = uc_query(obj->engine, qtype, &result);
            if (err == UC_ERR_OK) {
                RETVAL = result;
            } else {
                warn("Error in querying uc_engine. Error: %s", uc_strerror(err));
                XSRETURN_UNDEF;
            }
        } else {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

uc_err
uc_perl_errno(obj)
    uc_perl_t *obj
    CODE:
        if (obj && obj->engine) {
            RETVAL = uc_errno(obj->engine);
        } else {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

int
uc_perl_reg_write(obj,regid,input)
    uc_perl_t *obj
    int regid
    uint64_t input
    CODE:
        if (obj && obj->engine) {
            void *value = &input;
            //fprintf(stderr, "input (%d) = %lu\n", regid, input);
            uc_err err = uc_reg_write(obj->engine, regid, &value);
            if (err != UC_ERR_OK) {
                warn("Error in writing register to uc_engine. Error: %s", uc_strerror(err));
                XSRETURN_UNDEF;
            } else {
                RETVAL = 1;
            }
        } else {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

SV*
uc_perl_reg_read(obj,regid)
    uc_perl_t *obj
    int regid
    CODE:
        if (obj && obj->engine) {
            uint64_t value = 0;
            uc_err err = uc_reg_read(obj->engine, regid, &value);
            if (err != UC_ERR_OK) {
                warn("Error in reading register from uc_engine. Error: %s", uc_strerror(err));
                XSRETURN_UNDEF;
            } else {
                //fprintf(stderr, "read value for %d = %lu\n", regid, value);
                RETVAL = newSVu64(value);
            }
        } else {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

int
uc_perl_mem_map(obj,address,size,perms)
    uc_perl_t *obj
    uint64_t address
    size_t size
    uint32_t perms
    CODE:
        if (obj && obj->engine) {
            uc_err err = uc_mem_map(obj->engine, address, size, perms);
            if (err != UC_ERR_OK) {
                warn("Error in memory mapping region at address 0x%08x. Error: %s", address, uc_strerror(err));
                XSRETURN_UNDEF;
            } else {
                RETVAL = 1;
            }
        } else {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

int
uc_perl_mem_unmap(obj,address,size)
    uc_perl_t *obj
    uint64_t address
    size_t size
    CODE:
        if (obj && obj->engine) {
            uc_err err = uc_mem_unmap(obj->engine, address, size);
            if (err != UC_ERR_OK) {
                warn("Error in memory unmapping region at address 0x%08x. Error: %s", address, uc_strerror(err));
                XSRETURN_UNDEF;
            } else {
                RETVAL = 1;
            }
        } else {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

int
uc_perl_mem_write(obj,address,buffer)
    uc_perl_t *obj
    uint64_t address
    SV* buffer
    CODE:
        if (obj && obj->engine) {
            if (SvOK(buffer)) {
                size_t size = 0;
                uint8_t *bytes = SvPVbyte(buffer, size);
                //fprintf(stderr, "[%s:%d] size: %zu\n", __func__, __LINE__, size);
                uc_err err = uc_mem_write(obj->engine, address, bytes, size);
                if (err != UC_ERR_OK) {
                    warn("Failed to write memory at address 0x%08x. Error: %s", address, uc_strerror(err));
                    XSRETURN_UNDEF;
                } else {
                    RETVAL = 1;
                }
            } else {
                XSRETURN_UNDEF;
            }
        } else {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

int
uc_perl_mem_protect(obj,address,size,perms)
    uc_perl_t *obj
    uint64_t address
    size_t size
    uint32_t perms
    CODE:
        if (obj && obj->engine) {
            uc_err err = uc_mem_protect(obj->engine, address, size, perms);
            if (err != UC_ERR_OK) {
                warn("Error in memory protecting region at address 0x%08x. Error: %s", address, uc_strerror(err));
                XSRETURN_UNDEF;
            } else {
                RETVAL = 1;
            }
        } else {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

SV*
uc_perl_mem_read(obj,address,size)
    uc_perl_t *obj
    uint64_t address
    size_t size
    PREINIT:
        uc_err err = UC_ERR_OK;
        void *bytes = NULL;
    CODE:
        if (!obj || !obj->engine || size == 0) {
            XSRETURN_UNDEF;
        }
        bytes = calloc(size, 1);
        if (!bytes) {
            Perl_croak(aTHX_ "Out of memory allocating %zu bytes", size);
            XSRETURN_UNDEF;
        }
        err = uc_mem_read(obj->engine, address, bytes, size);
        if (err == UC_ERR_OK) {
            RETVAL = newSVpv(bytes, (STRLEN)size);
            free(bytes);
        } else {
            free(bytes);
            warn("Failed to read memory at address 0x%08x. Error: %s", address, uc_strerror(err));
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

int
uc_perl_emu_start(obj,addrbegin,addrend,timeout_us,count)
    uc_perl_t *obj
    uint64_t addrbegin
    uint64_t addrend
    uint64_t timeout_us
    size_t count
    PREINIT:
        uc_err err = UC_ERR_OK;
    CODE:
        if (!obj || !obj->engine) {
            XSRETURN_UNDEF;
        }
        err = uc_emu_start(obj->engine, addrbegin, addrend, timeout_us, count);
        if (err == UC_ERR_OK) {
            RETVAL = 1;
        } else {
            warn("Failed to start emulator. Error: %s", uc_strerror(err));
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL 

int
uc_perl_emu_stop(obj)
    uc_perl_t *obj
    CODE:
        if (obj && obj->engine) {
            uc_err err = uc_emu_stop(obj->engine);
            if (err == UC_ERR_OK) {
                RETVAL = 1;
            } else {
                warn("Failed to stop emulator. Error: %s", uc_strerror(err));
                XSRETURN_UNDEF;
            }
        } else {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL 

SV*
uc_perl_mem_regions(obj)
    uc_perl_t *obj
    PREINIT:
        uc_err err = UC_ERR_OK;
        uc_mem_region *regions = NULL;
        uint32_t count = 0, i = 0;
        AV *mapped = NULL;
    CODE:
        if (!obj || !obj->engine) {
            XSRETURN_UNDEF;
        }
        err = uc_mem_regions(obj->engine, &regions, &count);
        if (err != UC_ERR_OK) {
            Perl_croak(aTHX_ "Failed to retrieve mapped regions. Error: %s", uc_strerror(err));
            XSRETURN_UNDEF;
        }
        if (!regions || count == 0) {
            warn("No regions have been mapped");
            XSRETURN_UNDEF;
        }
        mapped = newAV();
        for (i = 0; i < count; ++i) {
            HV* hash = newHV();
            hv_store(hash, "begin", 5, newSVu64(regions[i].begin), 0);
            hv_store(hash, "end", 3, newSVu64(regions[i].end), 0);
            hv_store(hash, "perms", 5, newSVu64(regions[i].perms), 0);
            av_push(mapped, newRV_noinc((SV*)hash));
        }
        RETVAL = newRV_noinc((SV*)mapped);
        free(regions);
    OUTPUT:
        RETVAL
