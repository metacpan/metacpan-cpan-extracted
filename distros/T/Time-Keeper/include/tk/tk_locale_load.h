#ifndef TK_LOCALE_LOAD_H
#define TK_LOCALE_LOAD_H

/* Finding a locale by its code, and reading its data the first time it is
 * used. A locale is read once a process and never freed (K5), so the
 * pointer a value's locale id leads to is good for the life of the
 * process, from any thread.
 *
 * A section of share/locales.tkd holds only what differs from its parent
 * (fr-CA from fr, en-AU from en-001), so its parent is read first. English
 * is compiled in and never opens the file. */

static const tk_locale_data *tk_blob_data[TK_LOCALE_BLOBS];
static char *tk_locale_path = NULL;

#ifdef USE_ITHREADS
static perl_mutex tk_locale_mutex;
#  define TK_LOCALE_LOCK   MUTEX_LOCK(&tk_locale_mutex)
#  define TK_LOCALE_UNLOCK MUTEX_UNLOCK(&tk_locale_mutex)
#else
#  define TK_LOCALE_LOCK   NOOP
#  define TK_LOCALE_UNLOCK NOOP
#endif

#define TK_LOCALE_INHERIT 0xFFFFu
#define TK_LOCALE_NULL    0xFFFEu

/* ---- codes ---------------------------------------------------------------- */

/* The id of a code or alias: case does not matter and _ is -. -1 if none. */
static int
tk_locale_find(const char *s, STRLEN len)
{
    char key[64];
    STRLEN i;
    int lo = 0, hi = TK_LOCALE_LOOKUP - 1;
    STRLEN code_len, ca_len;
    const char *ca;
    tk_locale_split_ca(s, len, &code_len, &ca, &ca_len);   /* a -u-ca- extension is not part of the code */
    len = code_len;
    if (len == 0 || len >= sizeof key)
        return -1;
    for (i = 0; i < len; i++) {
        char ch = s[i];
        if (ch == '_')
            ch = '-';
        else if (ch >= 'A' && ch <= 'Z')
            ch += 32;
        else if (!((ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9') || ch == '-'))
            return -1;
        key[i] = ch;
    }
    key[len] = '\0';
    while (lo <= hi) {
        int mid = lo + (hi - lo) / 2;
        int c = strcmp(tk_locale_lookup[mid].key, key);
        if (c == 0)
            return tk_locale_lookup[mid].id;
        if (c < 0) lo = mid + 1; else hi = mid - 1;
    }
    return -1;
}

static uint16_t
tk_locale_id_from_sv(pTHX_ SV *sv, const char *what)
{
    STRLEN len;
    const char *s;
    int id;
    if (!sv || !SvOK(sv))
        croak("%s: which locale?", what);
    s = SvPV(sv, len);
    id = tk_locale_find(s, len);
    if (id < 0)
        croak("%s: there is no locale '%" SVf "'", what, SVfARG(sv));
    return (uint16_t)id;
}

/* ---- sections --------------------------------------------------------------- */

static unsigned
tk_u16(const unsigned char *p)
{
    return (unsigned)p[0] | ((unsigned)p[1] << 8);
}

static uint32_t
tk_u32(const unsigned char *p)
{
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

#define TK_SECTION_HEAD 36

/* A pool string, or NULL; 0 when the offset is past the pool. An offset
 * counts two-byte units since archive section version 4, so a pool may
 * reach 128 KB. */
static int
tk_section_str(const char *pool, size_t pool_len, unsigned off, const char **out)
{
    if (off == TK_LOCALE_NULL) {
        *out = NULL;
        return 1;
    }
    if ((size_t)off * 2 >= pool_len)
        return 0;
    *out = pool + (size_t)off * 2;
    return 1;
}

/* Interval formats sort by skeleton, then letter. */
static int
tk_interval_cmp(const tk_interval *x, const tk_interval *y)
{
    int c = strcmp(x->skeleton, y->skeleton);
    return c ? c : (int)x->letter - (int)y->letter;
}

/* Merge a parent's sorted records with a section's: a section's record
 * replaces its parent's with the same key, and one with no strings at all
 * removes it. */
static tk_zone_names *
tk_merge_names(const tk_zone_names *pa, unsigned np, const tk_zone_names *ch, unsigned nc, uint16_t *n_out)
{
    tk_zone_names *out;
    unsigned i = 0, j = 0, n = 0, k;
    Newxz(out, np + nc + 1, tk_zone_names);
    while (i < np || j < nc) {
        const tk_zone_names *take;
        if (j >= nc || (i < np && pa[i].id < ch[j].id))
            take = &pa[i++];
        else {
            if (i < np && pa[i].id == ch[j].id)
                i++;
            take = &ch[j++];
        }
        for (k = 0; k < TK_ZN_COUNT && !take->s[k]; k++)
            ;
        if (k < TK_ZN_COUNT)
            out[n++] = *take;
    }
    *n_out = (uint16_t)n;
    return out;
}

/* Read one section into a tk_locale_data, over its parent's. 0 and *err if
 * the bytes are not a section this build can read. */
static tk_locale_data *
tk_section_decode(const unsigned char *b, size_t len, const tk_locale_data *parent, int want_parent,
                  const char *id, const char **err)
{
    unsigned nfixed, nskel, nzone, nmeta, nterr, nrule, nwords, nival, plural, i, k;
    size_t idx, pool_at, pool_len;
    const char *pool;
    const unsigned char *p;
    tk_locale_data *d;
    const char **slot;
    const char *const *pslot;
    tk_pair *sk;
    tk_zone_names *zn, *mn;
    tk_terr_name *tn;
    tk_interval *iv;

    if (len < TK_SECTION_HEAD || memNE(b, "TKL4", 4)) {
        *err = "the section is not one this Time::Keeper reads";
        return NULL;
    }
    if ((tk_u16(b + 4) != TK_LOCALE_INHERIT) != (want_parent != 0)) {
        *err = "the section's parent is not the one expected";
        return NULL;
    }
    nfixed = tk_u16(b + 6);
    nskel  = tk_u16(b + 8);
    nzone  = tk_u16(b + 10);
    nmeta  = tk_u16(b + 12);
    nterr  = tk_u16(b + 14);
    nrule  = tk_u16(b + 16);
    nwords = tk_u16(b + 26);
    nival  = tk_u16(b + 28);
    plural = tk_u16(b + 34);
    if ((nfixed != TK_LOCALE_SLOTS && nfixed != TK_LOCALE_INHERIT) || (nwords != TK_WORD_SLOTS && nwords != TK_LOCALE_INHERIT)) {
        *err = "the section has a different number of names";
        return NULL;
    }
    if (plural >= TK_PLURAL_RULES) {
        *err = "the section names a plural rule this Time::Keeper lacks";
        return NULL;
    }
    idx = TK_SECTION_HEAD;
    pool_at = idx + 2 * ((nfixed == TK_LOCALE_INHERIT ? 0 : (size_t)nfixed) + 2 * nskel + 8 * nzone + 7 * nmeta + 2 * nterr
                         + (nrule == TK_LOCALE_INHERIT ? 0 : 3 * (size_t)nrule)
                         + (nwords == TK_LOCALE_INHERIT ? 0 : (size_t)nwords) + 3 * (size_t)nival);
    if (pool_at > len || (len > pool_at && b[len - 1] != '\0')) {
        *err = "the section is cut short";
        return NULL;
    }
    pool = (const char *)b + pool_at;
    pool_len = len - pool_at;

    Newxz(d, 1, tk_locale_data);
    d->id = id;
    d->first_day = (uint8_t)tk_u16(b + 18);
    d->min_days = (uint8_t)tk_u16(b + 20);
    d->hour_cycle_24 = (uint8_t)tk_u16(b + 22);
    d->ascii_digits = (uint8_t)tk_u16(b + 24);
    d->weekend_start = (uint8_t)tk_u16(b + 30);
    d->weekend_end = (uint8_t)tk_u16(b + 32);
    d->plural = (uint16_t)plural;
    if (d->weekend_start < 1 || d->weekend_start > 7 || d->weekend_end < 1 || d->weekend_end > 7)
        goto bad;

    p = b + idx;
    slot = (const char **)&d->s;
    if (nfixed == TK_LOCALE_INHERIT) {          /* every name the parent's: no table (section version 4) */
        if (!parent) goto bad;
        d->s = parent->s;
        nfixed = 0;
    }
    pslot = parent ? (const char *const *)&parent->s : NULL;
    for (i = 0; i < nfixed; i++, p += 2) {
        unsigned off = tk_u16(p);
        if (off == TK_LOCALE_INHERIT) {
            if (!pslot) goto bad;
            slot[i] = pslot[i];
        }
        else if (!tk_section_str(pool, pool_len, off, &slot[i]))
            goto bad;
    }

    Newxz(sk, (parent ? parent->n_skeletons : 0) + nskel + 1, tk_pair);
    {
        const tk_pair *pa = parent ? parent->skeletons : NULL;
        unsigned np = parent ? parent->n_skeletons : 0, a = 0, n = 0;
        for (k = 0; k <= nskel; k++) {
            tk_pair c;
            if (k < nskel) {
                if (!tk_section_str(pool, pool_len, tk_u16(p), &c.key) || !c.key
                    || !tk_section_str(pool, pool_len, tk_u16(p + 2), &c.value))
                    goto bad;
                p += 4;
            }
            while (a < np && (k == nskel || strcmp(pa[a].key, c.key) < 0))
                sk[n++] = pa[a++];
            if (k == nskel)
                break;
            if (a < np && strEQ(pa[a].key, c.key))
                a++;
            if (c.value)
                sk[n++] = c;
        }
        d->skeletons = sk;
        d->n_skeletons = (uint16_t)n;
    }

    Newxz(zn, nzone + 1, tk_zone_names);
    for (k = 0; k < nzone; k++, p += 16) {
        zn[k].id = (uint16_t)tk_u16(p);
        for (i = 0; i < 7; i++)
            if (!tk_section_str(pool, pool_len, tk_u16(p + 2 + 2 * i), &zn[k].s[i]))
                goto bad;
    }
    Newxz(mn, nmeta + 1, tk_zone_names);
    for (k = 0; k < nmeta; k++, p += 14) {
        mn[k].id = (uint16_t)tk_u16(p);
        for (i = 0; i < 6; i++)
            if (!tk_section_str(pool, pool_len, tk_u16(p + 2 + 2 * i), &mn[k].s[i]))
                goto bad;
    }
    if (parent) {
        d->zones = tk_merge_names(parent->zones, parent->n_zones, zn, nzone, &d->n_zones);
        d->metazones = tk_merge_names(parent->metazones, parent->n_metazones, mn, nmeta, &d->n_metazones);
        Safefree(zn);
        Safefree(mn);
    }
    else {
        d->zones = zn;
        d->n_zones = (uint16_t)nzone;
        d->metazones = mn;
        d->n_metazones = (uint16_t)nmeta;
    }

    Newxz(tn, (parent ? parent->n_territories : 0) + nterr + 1, tk_terr_name);
    {
        const tk_terr_name *pa = parent ? parent->territories : NULL;
        unsigned np = parent ? parent->n_territories : 0, a = 0, n = 0;
        for (k = 0; k <= nterr; k++) {
            tk_terr_name c;
            if (k < nterr) {
                c.id = (uint16_t)tk_u16(p);
                if (!tk_section_str(pool, pool_len, tk_u16(p + 2), &c.name))
                    goto bad;
                p += 4;
            }
            while (a < np && (k == nterr || pa[a].id < c.id))
                tn[n++] = pa[a++];
            if (k == nterr)
                break;
            if (a < np && pa[a].id == c.id)
                a++;
            if (c.name)
                tn[n++] = c;
        }
        d->territories = tn;
        d->n_territories = (uint16_t)n;
    }

    if (nrule == TK_LOCALE_INHERIT) {
        if (!parent) goto bad;
        d->rules = parent->rules;
        d->n_rules = parent->n_rules;
    }
    else {
        tk_period_rule *r;
        Newxz(r, nrule + 1, tk_period_rule);
        for (k = 0; k < nrule; k++, p += 6) {
            r[k].period = (uint8_t)tk_u16(p);
            r[k].from = (uint16_t)tk_u16(p + 2);
            r[k].before = (uint16_t)tk_u16(p + 4);
            if (r[k].period >= TK_DP_COUNT) goto bad;
        }
        d->rules = r;
        d->n_rules = (uint16_t)nrule;
    }
    slot = (const char **)&d->w;
    if (nwords == TK_LOCALE_INHERIT) {          /* every word the parent's: no table */
        if (!parent) goto bad;
        d->w = parent->w;
        nwords = 0;
    }
    pslot = parent ? (const char *const *)&parent->w : NULL;
    for (i = 0; i < nwords; i++, p += 2) {
        unsigned off = tk_u16(p);
        if (off == TK_LOCALE_INHERIT) {
            if (!pslot) goto bad;
            slot[i] = pslot[i];
        }
        else if (!tk_section_str(pool, pool_len, off, &slot[i]))
            goto bad;
    }

    Newxz(iv, (parent ? parent->n_intervals : 0) + nival + 1, tk_interval);
    {
        const tk_interval *pa = parent ? parent->intervals : NULL;
        unsigned np = parent ? parent->n_intervals : 0, a = 0, n = 0;
        for (k = 0; k <= nival; k++) {
            tk_interval c;
            if (k < nival) {
                unsigned letter = tk_u16(p + 2);
                if (!tk_section_str(pool, pool_len, tk_u16(p), &c.skeleton) || !c.skeleton || letter > 0x7f
                    || !tk_section_str(pool, pool_len, tk_u16(p + 4), &c.pattern))
                    goto bad;
                c.letter = (char)letter;
                p += 6;
            }
            while (a < np && (k == nival || tk_interval_cmp(&pa[a], &c) < 0))
                iv[n++] = pa[a++];
            if (k == nival)
                break;
            if (a < np && tk_interval_cmp(&pa[a], &c) == 0)
                a++;
            if (c.pattern)
                iv[n++] = c;
        }
        d->intervals = iv;
        d->n_intervals = (uint16_t)n;
    }

    for (i = 0; i < TK_W_COUNT; i++)
        if (!d->s.periods[i][TK_DP_AM] || !d->s.periods[i][TK_DP_PM])
            goto bad;
    *err = NULL;
    return d;
bad:
    /* A bad section is not freed: the parts already shared with a parent
     * are not this one's to free, and a bad file is fatal anyway. */
    *err = "the section is corrupt";
    return NULL;
}

/* ---- the file -------------------------------------------------------------- */

/* Whether a file can be opened for reading. */
static int
tk_readable(pTHX_ const char *path)
{
    PerlIO *f = PerlIO_open(path, "rb");
    if (!f)
        return 0;
    PerlIO_close(f);
    return 1;
}

/* Where share/locales.tkd was installed: beside Time/Keeper.pm, as
 * Time/Keeper/locales.tkd, wherever %INC says that was loaded from, or
 * anywhere in @INC. */
static char *
tk_locale_file(pTHX)
{
    SV **pm = hv_fetchs(GvHVn(PL_incgv), "Time/Keeper.pm", 0);
    AV *inc = GvAVn(PL_incgv);
    SSize_t i;
    if (pm && SvOK(*pm)) {
        STRLEN l;
        const char *s = SvPV(*pm, l);
        if (l > 3 && memEQ(s + l - 3, ".pm", 3)) {
            SV *path = sv_2mortal(newSVpvn(s, l - 3));
            sv_catpvs(path, "/locales.tkd");
            if (tk_readable(aTHX_ SvPV_nolen(path)))
                return savepv(SvPV_nolen(path));
        }
    }
    for (i = 0; i <= av_len(inc); i++) {
        SV **e = av_fetch(inc, i, 0);
        SV *path;
        if (!e || !SvOK(*e) || SvROK(*e))
            continue;
        path = sv_2mortal(newSVsv(*e));
        sv_catpvs(path, "/Time/Keeper/locales.tkd");
        if (tk_readable(aTHX_ SvPV_nolen(path)))
            return savepv(SvPV_nolen(path));
    }
    return NULL;
}

/* One section's bytes from the file, or croak. Called with the lock held;
 * any croak lets it go first. */
static unsigned char *
tk_locale_read_blob(pTHX_ unsigned blob, size_t *len)
{
    unsigned char head[32], ent[8];
    unsigned char *buf;
    PerlIO *f;
    uint32_t off, n;
    const char *why = NULL;

    if (!tk_locale_path)
        tk_locale_path = tk_locale_file(aTHX);
    if (!tk_locale_path) {
        TK_LOCALE_UNLOCK;
        croak("Time::Keeper: cannot find its locale data, Time/Keeper/locales.tkd, in @INC");
    }
    f = PerlIO_open(tk_locale_path, "rb");
    if (!f) {
        TK_LOCALE_UNLOCK;
        croak("Time::Keeper: cannot open %s: %s", tk_locale_path, Strerror(errno));
    }
    if (PerlIO_read(f, head, 32) != 32 || memNE(head, "TKD1", 4))
        why = "it is not Time::Keeper's locale data";
    else if (tk_u32(head + 4) != TK_LOCALE_BLOBS || tk_u32(head + 8) != TK_LOCALE_STAMP)
        why = "it is from a different build of Time::Keeper";
    else if (PerlIO_seek(f, (Off_t)(32 + 8 * blob), SEEK_SET) != 0 || PerlIO_read(f, ent, 8) != 8)
        why = "its index is cut short";
    if (why) {
        PerlIO_close(f);
        TK_LOCALE_UNLOCK;
        croak("Time::Keeper: cannot use %s: %s", tk_locale_path, why);
    }
    off = tk_u32(ent);
    n = tk_u32(ent + 4);
    Newx(buf, n ? n : 1, unsigned char);
    if (PerlIO_seek(f, (Off_t)off, SEEK_SET) != 0 || PerlIO_read(f, buf, n) != (SSize_t)n) {
        Safefree(buf);
        PerlIO_close(f);
        TK_LOCALE_UNLOCK;
        croak("Time::Keeper: cannot use %s: a section is cut short", tk_locale_path);
    }
    PerlIO_close(f);
    *len = n;
    return buf;
}

/* The data of a section, reading it (and its parents) if it has not been.
 * Called with the lock held. */
static const tk_locale_data *
tk_blob_load(pTHX_ unsigned blob, const char *id)
{
    const unsigned char *b;
    unsigned char *mine = NULL;
    size_t len;
    const tk_locale_data *parent = NULL;
    tk_locale_data *d;
    const char *err;
    unsigned pid;

    if (tk_blob_data[blob])
        return tk_blob_data[blob];
    if (blob == 0) {
        b = tk_locale_en_blob;
        len = sizeof tk_locale_en_blob;
    }
    else
        b = mine = tk_locale_read_blob(aTHX_ blob, &len);
    pid = len >= TK_SECTION_HEAD ? tk_u16(b + 4) : TK_LOCALE_INHERIT;
    if (pid != TK_LOCALE_INHERIT) {
        if (pid >= TK_LOCALE_COUNT || tk_locale_codes[pid].blob == blob) {
            Safefree(mine);
            TK_LOCALE_UNLOCK;
            croak("Time::Keeper: the locale data for %s names a parent it cannot have", id);
        }
        parent = tk_blob_load(aTHX_ tk_locale_codes[pid].blob, tk_locale_codes[tk_locale_codes[pid].blob].code);
    }
    d = tk_section_decode(b, len, parent, pid != TK_LOCALE_INHERIT, id, &err);
    if (!d) {
        Safefree(mine);
        TK_LOCALE_UNLOCK;
        croak("Time::Keeper: the locale data for %s cannot be read: %s", id, err);
    }
    tk_blob_data[blob] = d;
    return d;
}

static const tk_locale_data *
tk_locale_get(pTHX_ unsigned id)
{
    const tk_locale_data *d;
    unsigned blob;
    if (id >= TK_LOCALE_COUNT)
        id = 0;
    blob = tk_locale_codes[id].blob;
    d = tk_blob_data[blob];
    if (d)
        return d;
    TK_LOCALE_LOCK;
    d = tk_blob_load(aTHX_ blob, tk_locale_codes[blob].code);
    TK_LOCALE_UNLOCK;
    return d;
}

#endif
