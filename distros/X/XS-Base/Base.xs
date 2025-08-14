#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <stdlib.h>

#ifdef _WIN32
  #include <windows.h>
  #if defined(_WIN32_WINNT) && _WIN32_WINNT >= 0x0600
    static SRWLOCK rwlock;
    #define INIT_LOCK() InitializeSRWLock(&rwlock)
    #define RLOCK() AcquireSRWLockShared(&rwlock)
    #define RUNLOCK() ReleaseSRWLockShared(&rwlock)
    #define WLOCK() AcquireSRWLockExclusive(&rwlock)
    #define WUNLOCK() ReleaseSRWLockExclusive(&rwlock)
  #else
    static CRITICAL_SECTION cs_lock;
    #define INIT_LOCK() InitializeCriticalSection(&cs_lock)
    #define RLOCK() EnterCriticalSection(&cs_lock)
    #define RUNLOCK() LeaveCriticalSection(&cs_lock)
    #define WLOCK() EnterCriticalSection(&cs_lock)
    #define WUNLOCK() LeaveCriticalSection(&cs_lock)
  #endif
#else
  #include <pthread.h>
  static pthread_rwlock_t rwlock = PTHREAD_RWLOCK_INITIALIZER;
  #define INIT_LOCK() /* pthread rwlock is statically inited */
  #define RLOCK() pthread_rwlock_rdlock(&rwlock)
  #define RUNLOCK() pthread_rwlock_unlock(&rwlock)
  #define WLOCK() pthread_rwlock_wrlock(&rwlock)
  #define WUNLOCK() pthread_rwlock_unlock(&rwlock)
#endif

/* 全局 root */
static SV *global_root = NULL;
static int strict_mode = 1;

/* 懒初始化全局 root（hashref） */
static void ensure_global_root(void) {
    if (!global_root) {
        HV *h = newHV();
        SV *rv = newRV_noinc((SV*)h);    /* rv refcount = 1 */
        global_root = rv;                /* 保存为全局 */
        /* 不需要额外 inc；global_root 本身持有该 RV 的唯一引用 */
    }
}

static char **split_path(const char *path, I32 *count) {
    if (!path || !*path) { *count = 0; return NULL; }
    char *s = strdup(path);
    if (!s) { *count = 0; return NULL; }
    I32 n = 1;
    const char *p = path;
    while ((p = strstr(p, "->"))) { n++; p += 2; }
    char **parts = (char**)malloc(sizeof(char*) * n);
    if (!parts) { free(s); *count = 0; return NULL; }
    I32 idx = 0;
    char *cur = s;
    char *sep;
    while ((sep = strstr(cur, "->"))) {
        *sep = '\0';
        parts[idx++] = strdup(cur);
        cur = sep + 2;
    }
    parts[idx++] = strdup(cur);
    *count = idx;
    free(s);
    return parts;
}

static void free_parts(char **parts, I32 count) {
    if (!parts) return;
    for (I32 i = 0; i < count; i++) if (parts[i]) free(parts[i]);
    free(parts);
}

static int hv_is_empty(HV *hv) {
    HE *he;
    hv_iterinit(hv);
    he = hv_iternext(hv);
    return he == NULL;
}

static HV *get_root_hv(void) {
    ensure_global_root();
    return (HV*)SvRV(global_root);
}

/* 写入：严格/宽松路径处理，返回值的“拷贝”（newSVsv），方便直接作为返回值 */
static SV *xsbase_set_by_path(const char *path, SV *val) {
    ensure_global_root();
    if (!path) croak("XS::Base::has: key required");

    I32 parts_n = 0;
    char **parts = split_path(path, &parts_n);
    if (!parts || parts_n == 0) { free_parts(parts, parts_n); croak("invalid key"); }

    HV *hv = get_root_hv();

    for (I32 i = 0; i < parts_n; i++) {
        const char *k = parts[i];
        I32 klen = (I32)strlen(k);

        if (i == parts_n - 1) {
            SV *to_store = newSVsv(val);           /* 拷贝写入 */
            (void)hv_store(hv, k, klen, to_store, 0); /* hv_store 不会自动 inc，传的 SV 应是我们要交给 HV 管理的“所有权” */
            SV *ret = newSVsv(to_store);           /* 再拷贝一份作为返回值，避免外面改动影响内部存储 */
            free_parts(parts, parts_n);
            return ret;
        } else {
            SV **psv = hv_fetch(hv, k, klen, 0);
            if (psv && *psv) {
                SV *sv = *psv;
                if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV) {
                    hv = (HV*)SvRV(sv);
                } else {
                    if (strict_mode) {
                        free_parts(parts, parts_n);
                        croak("XS::Base::has: path collision at intermediate node '%s' (not a hashref) - strict mode", k);
                    } else {
                        /* 宽松模式：覆盖非 hashref 中间节点为新 hashref */
                        SV *old = hv_delete(hv, k, klen, G_DISCARD);
                        if (old) SvREFCNT_dec(old);
                        HV *newhv = newHV();
                        SV *r = newRV_noinc((SV*)newhv); /* r refcount=1 交给 HV */
                        (void)hv_store(hv, k, klen, r, 0);
                        hv = newhv;
                    }
                }
            } else {
                /* 不存在：创建中间 hashref */
                HV *newhv = newHV();
                SV *r = newRV_noinc((SV*)newhv);
                (void)hv_store(hv, k, klen, r, 0);
                hv = newhv;
            }
        }
    }

    free_parts(parts, parts_n);
    return NULL; /* 不会走到这 */
}

/* 读取：返回“拷贝”（newSVsv），避免把 HV 里的 SV 直接 inc 返回导致生命周期复杂 */
static SV *xsbase_get_by_path(const char *path) {
    ensure_global_root();
    if (!path || !*path) return NULL;

    HV *hv = get_root_hv();
    I32 parts_n = 0;
    char **parts = split_path(path, &parts_n);
    if (!parts || parts_n == 0) { free_parts(parts, parts_n); return NULL; }

    SV *val = NULL;

    for (I32 i = 0; i < parts_n; i++) {
        STRLEN klen = (STRLEN)strlen(parts[i]);
        SV **svp = hv_fetch(hv, parts[i], (I32)klen, 0);
        if (!svp || !*svp) { val = NULL; break; }

        SV *sv = *svp;
        if (i == parts_n - 1) {
            val = newSVsv(sv);   /* 返回拷贝 */
            break;
        }
        if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV) {
            hv = (HV*)SvRV(sv);
        } else {
            val = NULL;
            break;
        }
    }

    free_parts(parts, parts_n);
    return val; /* 可能为 NULL */
}

/* def: 不存在才写，返回值的拷贝 */
static SV *xsbase_def_by_path(const char *path, SV *val) {
    ensure_global_root();
    SV *existing = xsbase_get_by_path(path);
    if (existing) return existing;          /* 已是“拷贝” */
    return xsbase_set_by_path(path, val);   /* 返回“拷贝” */
}

/* del: 删除叶子并回溯清理空父节点 */
static int xsbase_del_by_path(const char *path) {
    ensure_global_root();
    if (!path || !*path) croak("XS::Base::del: key required");

    I32 parts_n = 0;
    char **parts = split_path(path, &parts_n);
    if (!parts || parts_n == 0) { free_parts(parts, parts_n); croak("invalid key"); }

    HV *hv = get_root_hv();
    HV **parents = (HV**)malloc(sizeof(HV*) * parts_n);
    char **pkeys = (char**)malloc(sizeof(char*) * parts_n);
    if (!parents || !pkeys) {
        free(parents); free(pkeys); free_parts(parts, parts_n);
        croak("malloc failed");
    }

    int ok = 0;
    for (I32 i = 0; i < parts_n; i++) {
        parents[i] = hv;
        pkeys[i] = strdup(parts[i]);

        STRLEN klen = (STRLEN)strlen(parts[i]);
        SV **svp = hv_fetch(hv, parts[i], (I32)klen, 0);
        if (!svp || !*svp) { ok = 0; break; }

        SV *sv = *svp;
        if (i < parts_n - 1) {
            if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV) {
                hv = (HV*)SvRV(sv);
            } else {
                ok = 0; break;
            }
        } else {
            SV *removed = hv_delete(parents[i], pkeys[i], (I32)strlen(pkeys[i]), G_DISCARD);
            if (removed) SvREFCNT_dec(removed);

            for (I32 j = parts_n - 1; j >= 0; j--) {
                if (hv_is_empty(parents[j]) && j > 0) {
                    SV *rem = hv_delete(parents[j-1], pkeys[j-1], (I32)strlen(pkeys[j-1]), G_DISCARD);
                    if (rem) SvREFCNT_dec(rem);
                } else break;
            }
            ok = 1; break;
        }
    }

    for (I32 i = 0; i < parts_n; i++) if (pkeys[i]) free(pkeys[i]);
    free(parents);
    free(pkeys);
    free_parts(parts, parts_n);
    return ok;
}

static void xsbase_clr_all(void) {
    ensure_global_root();
    hv_clear(get_root_hv());
}

/* 返回同一个 RV（global_root），并 inc；Perl 端可配合 _dec_sv 释放 */
static SV *xsbase_get_root_ref(void) {
    ensure_global_root();
    SvREFCNT_inc(global_root);
    return global_root;
}

static void xsbase_replace_root(SV *newroot) {
    ensure_global_root();
    if (!newroot || !SvROK(newroot) || SvTYPE(SvRV(newroot)) != SVt_PVHV) {
        croak("XS::Base::replace_root requires a hashref");
    }
    HV *src = (HV*)SvRV(newroot);
    HV *dst = get_root_hv();

    hv_clear(dst);
    hv_iterinit(src);
    HE *he;
    while ((he = hv_iternext(src)) != NULL) {
        SV *keysv = hv_iterkeysv(he);
        STRLEN klen;
        char *k = (char*)SvPV(keysv, klen);
        SV *val = HeVAL(he);
        SV *copy = newSVsv(val);               /* 拷贝 */
        (void)hv_store(dst, k, (I32)klen, copy, 0);
    }
}

static void xsbase_dec_sv(SV *sv) {
    if (sv) SvREFCNT_dec(sv);
}

/* ---------- XS 绑定 ---------- */

MODULE = XS::Base    PACKAGE = XS::Base

BOOT:
    INIT_LOCK();
	

PROTOTYPES: DISABLED

SV *
has(key, ...)
    SV *key
PPCODE:
{
    //dXSARGS;
	ensure_global_root();
    if (items != 1 && items != 2) croak("Usage: XS::Base::has(KEY) or XS::Base::has(KEY, VAL)");
    STRLEN klen;
    char *k = (char*)SvPV(key, klen);

    if (items == 2) {
        /* 写操作：独占写锁 */
        SV *val = ST(1);
        WLOCK();
        SV *ret = xsbase_set_by_path(k, val);
        WUNLOCK();
        if (ret) ST(0) = ret;
        else ST(0) = &PL_sv_undef;
    } else {
        /* 读操作：共享读锁 */
        RLOCK();
        SV *ret = xsbase_get_by_path(k);
        RUNLOCK();
        if (ret) ST(0) = ret;
        else ST(0) = &PL_sv_undef;
    }
    XSRETURN(1);
}

int
del(key)
    SV *key
CODE:
{
    ensure_global_root();
    STRLEN klen;
    char *k = (char*)SvPV(key, klen);
    WLOCK();
    int r = xsbase_del_by_path(k);
    WUNLOCK();
    RETVAL = r;
}
OUTPUT:
    RETVAL

SV *
def(key, val)
    SV *key
    SV *val
PPCODE:
{
    dXSARGS;
    ensure_global_root();

    if (items != 2) croak("Usage: XS::Base::def(KEY, VAL)");

    STRLEN klen;
    char *k = (char*)SvPV(key, klen);

    WLOCK();
    SV *ret = xsbase_def_by_path(k, val);  /* 拷贝 */
    WUNLOCK();

    EXTEND(SP, 1);
    if (ret) { PUSHs(sv_2mortal(ret)); } else { PUSHs(&PL_sv_undef); }
    XSRETURN(1);
}

void
clr()
CODE:
{
    ensure_global_root();
    WLOCK();
    xsbase_clr_all();
    WUNLOCK();
}

SV *
get_root_ref()
CODE:
{
    ensure_global_root();
    RLOCK();
    SV *r = xsbase_get_root_ref(); /* inc 后返回同一 RV */
    RUNLOCK();

    /* 返回的 r 不能 mortal；让上层决定是否调用 _dec_sv 释放 */
    ST(0) = r;
    XSRETURN(1);
}

void
replace_root(newroot)
    SV *newroot
CODE:
{
    ensure_global_root();
    WLOCK();
    xsbase_replace_root(newroot);
    WUNLOCK();
}

void
_dec_sv(sv)
    SV *sv
CODE:
{
    xsbase_dec_sv(sv);
}

void
set_strict_mode(onoff)
    int onoff
CODE:
{
    strict_mode = onoff ? 1 : 0;
}

int
get_strict_mode()
CODE:
{
    RETVAL = strict_mode;
}
OUTPUT:
    RETVAL
