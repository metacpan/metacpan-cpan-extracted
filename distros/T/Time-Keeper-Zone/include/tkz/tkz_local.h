#ifndef TKZ_LOCAL_H
#define TKZ_LOCAL_H

/* This process's zone, found by name and never by reading the system's
 * zone data: the TZ variable, then the name /etc/localtime links to, then
 * /etc/timezone, then /etc/sysconfig/clock, then on Windows the zone key
 * name mapped through CLDR's table. UTC when nothing names a zone that is
 * compiled in.
 *
 * TZ is passed in, never read with getenv: under PERL_IMPLICIT_SYS getenv
 * does not see %ENV. NULL means TZ is not set; an empty TZ means UTC, as
 * it does to the C library. */

#ifdef WIN32
#  include <windows.h>
#else
#  include <unistd.h>
#endif
#include <stdio.h>

/* The zone a path names, if it holds ".../zoneinfo/Area/City". */
static int
tkz_zone_from_path(const char *p, size_t len)
{
    size_t i;
    static const char key[] = "zoneinfo/";
    for (i = len; i-- > 0; ) {
        if (i + sizeof(key) - 1 <= len && memcmp(p + i, key, sizeof(key) - 1) == 0) {
            size_t start = i + sizeof(key) - 1;
            return tkz_lookup_name(p + start, len - start);
        }
    }
    return -1;
}

static int
tkz_zone_from_tz(const char *tz, size_t len)
{
    int id;
    if (len && tz[0] == ':') {
        tz++;
        len--;
    }
    if (len == 0)
        return tkz_lookup_name("Etc/UTC", 7);
    if (tz[0] == '/')
        return tkz_zone_from_path(tz, len);
    id = tkz_lookup_name(tz, len);
    return id;
}

/* The first line of a file, trimmed of space; 0 if there is none. */
static size_t
tkz_first_line(const char *path, char *buf, size_t size)
{
    FILE *fh = fopen(path, "r");
    size_t n;
    if (!fh)
        return 0;
    if (!fgets(buf, (int)size, fh)) {
        fclose(fh);
        return 0;
    }
    fclose(fh);
    n = strlen(buf);
    while (n && (buf[n - 1] == '\n' || buf[n - 1] == '\r' || buf[n - 1] == ' ' || buf[n - 1] == '\t'))
        buf[--n] = '\0';
    while (n && (buf[0] == ' ' || buf[0] == '\t')) {
        memmove(buf, buf + 1, n);
        n--;
    }
    return n;
}

/* ZONE="Europe/London" in a Red Hat style /etc/sysconfig/clock. */
static int
tkz_zone_from_clock_file(const char *path)
{
    FILE *fh = fopen(path, "r");
    char line[256];
    int id = -1;
    if (!fh)
        return -1;
    while (id < 0 && fgets(line, sizeof line, fh)) {
        char *p = line, *q;
        while (*p == ' ' || *p == '\t') p++;
        if (strncmp(p, "ZONE=", 5) && strncmp(p, "TIMEZONE=", 9))
            continue;
        p = strchr(p, '=') + 1;
        if (*p == '"' || *p == '\'') p++;
        q = p;
        while (*q && *q != '"' && *q != '\'' && *q != '\n' && *q != '\r' && *q != ' ')
            q++;
        id = tkz_lookup_name(p, (size_t)(q - p));
    }
    fclose(fh);
    return id;
}

static int
tkz_windows_lookup(const char *name)
{
    int lo = 0, hi = TKZ_WINDOWS_COUNT - 1;
    while (lo <= hi) {
        int mid = lo + (hi - lo) / 2;
        int c = strcmp(tkz_windows_names + tkz_windows[mid].name, name);
        if (c == 0) {
            const char *zn = tkz_names + tkz_zones[tkz_windows[mid].zone].name;
            return tkz_lookup_name(zn, strlen(zn));
        }
        if (c < 0) lo = mid + 1; else hi = mid - 1;
    }
    return -1;
}

/* Each source tried in turn, with the files named so a test can stand in
 * its own. NULL skips a file. */
static int
tkz_local_zone_from(const char *tz, size_t tzlen,
                    const char *localtime_link, const char *timezone_file,
                    const char *clock_file)
{
    int id;
    char buf[1024];
    if (tz && (id = tkz_zone_from_tz(tz, tzlen)) >= 0)
        return id;
#ifndef WIN32
    if (localtime_link) {
        ssize_t n = readlink(localtime_link, buf, sizeof buf - 1);
        if (n > 0 && (id = tkz_zone_from_path(buf, (size_t)n)) >= 0)
            return id;
    }
#endif
    if (timezone_file) {
        size_t n = tkz_first_line(timezone_file, buf, sizeof buf);
        if (n && (id = tkz_lookup_name(buf, n)) >= 0)
            return id;
    }
    if (clock_file && (id = tkz_zone_from_clock_file(clock_file)) >= 0)
        return id;
#ifdef WIN32
    {
        DYNAMIC_TIME_ZONE_INFORMATION dz;
        if (GetDynamicTimeZoneInformation(&dz) != TIME_ZONE_ID_INVALID) {
            int i;
            for (i = 0; i < 127 && dz.TimeZoneKeyName[i]; i++)
                buf[i] = dz.TimeZoneKeyName[i] < 128 ? (char)dz.TimeZoneKeyName[i] : '?';
            buf[i] = '\0';
            if ((id = tkz_windows_lookup(buf)) >= 0)
                return id;
        }
    }
#endif
    return tkz_lookup_name("Etc/UTC", 7);
}

static int
tkz_local_zone(const char *tz, size_t tzlen)
{
    return tkz_local_zone_from(tz, tzlen, "/etc/localtime", "/etc/timezone",
                               "/etc/sysconfig/clock");
}

#endif
