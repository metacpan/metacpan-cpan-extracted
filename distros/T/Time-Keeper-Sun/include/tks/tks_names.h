#ifndef TKS_NAMES_H
#define TKS_NAMES_H

/* Zone names and locale codes, interned once a process: a place and a day
 * hold a 16-bit id rather than the string. The table is shared by every
 * interpreter (the strings are in shared memory and never freed: a process
 * meets few zones), so an id made in one thread is good in another, and it
 * is guarded by a mutex where there are threads. */

#define TKS_NAMES_MAX 65535

static char **tks_names = NULL;
static STRLEN *tks_names_len = NULL;
static int tks_names_n = 0, tks_names_cap = 0;
#ifdef USE_ITHREADS
static perl_mutex tks_names_mutex;
#define TKS_NAMES_LOCK   MUTEX_LOCK(&tks_names_mutex)
#define TKS_NAMES_UNLOCK MUTEX_UNLOCK(&tks_names_mutex)
#else
#define TKS_NAMES_LOCK
#define TKS_NAMES_UNLOCK
#endif

static int tks_names_lookups = 0;       /* for a test door: how many interns searched */

static int
tks_name_id(pTHX_ const char *s, STRLEN len)
{
    int i, id;
    char *copy;
    TKS_NAMES_LOCK;
    tks_names_lookups++;
    for (i = 0; i < tks_names_n; i++)
        if (tks_names_len[i] == len && memEQ(tks_names[i], s, len)) {
            TKS_NAMES_UNLOCK;
            return i;
        }
    if (tks_names_n >= TKS_NAMES_MAX) {
        TKS_NAMES_UNLOCK;
        croak("Time::Keeper::Sun: more than %d zone and locale names in one process", TKS_NAMES_MAX);
    }
    if (tks_names_n == tks_names_cap) {
        int cap = tks_names_cap ? tks_names_cap * 2 : 64;
        tks_names = (char **)PerlMemShared_realloc(tks_names, cap * sizeof *tks_names);
        tks_names_len = (STRLEN *)PerlMemShared_realloc(tks_names_len, cap * sizeof *tks_names_len);
        tks_names_cap = cap;
    }
    copy = (char *)PerlMemShared_malloc(len + 1);
    memcpy(copy, s, len);
    copy[len] = '\0';
    id = tks_names_n;
    tks_names[id] = copy;
    tks_names_len[id] = len;
    tks_names_n++;
    TKS_NAMES_UNLOCK;
    return id;
}

/* The string of an id, as a new SV; UTF-8 since zone names are read so. */
static SV *
tks_name_sv(pTHX_ int id)
{
    const char *s;
    STRLEN len;
    SV *sv;
    TKS_NAMES_LOCK;
    if (id < 0 || id >= tks_names_n) {
        TKS_NAMES_UNLOCK;
        croak("Time::Keeper::Sun: no name has the id %d", id);
    }
    s = tks_names[id];
    len = tks_names_len[id];
    TKS_NAMES_UNLOCK;
    sv = newSVpvn(s, len);
    SvUTF8_on(sv);
    return sv;
}

#endif
