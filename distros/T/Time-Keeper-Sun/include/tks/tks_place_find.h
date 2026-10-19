#ifndef TKS_PLACE_FIND_H
#define TKS_PLACE_FIND_H

/* A zone's representative place by name, from the generated table: a
 * binary search, case-sensitive as zone names are. */
static const tks_place_row *
tks_place_find(const char *name, STRLEN len)
{
    int lo = 0, hi = TKS_PLACES_COUNT - 1;
    while (lo <= hi) {
        int mid = (lo + hi) / 2;
        const char *n = tks_places[mid].name;
        int c = strncmp(n, name, len);
        if (c == 0)
            c = n[len] == '\0' ? 0 : 1;
        if (c == 0)
            return &tks_places[mid];
        if (c < 0)
            lo = mid + 1;
        else
            hi = mid - 1;
    }
    return NULL;
}

#endif
