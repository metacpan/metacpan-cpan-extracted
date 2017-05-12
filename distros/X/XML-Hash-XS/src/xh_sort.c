#include "xh_config.h"
#include "xh_core.h"

static int
xh_sort_hash_cmp(const void *p1, const void *p2)
{
    return xh_strcmp(((xh_sort_hash_t *) p1)->key, ((xh_sort_hash_t *) p2)->key);
}

xh_sort_hash_t *
xh_sort_hash(HV *hash, size_t len)
{
    xh_sort_hash_t *sorted_hash;
    size_t          i;

    sorted_hash = malloc(sizeof(xh_sort_hash_t) * len);
    if (sorted_hash == NULL) {
        croak("Memory allocation error");
    }

    hv_iterinit(hash);

    for (i = 0; i < len; i++) {
        sorted_hash[i].value = hv_iternextsv(hash, (char **) &sorted_hash[i].key, &sorted_hash[i].key_len);
    }

    qsort(sorted_hash, len, sizeof(xh_sort_hash_t), xh_sort_hash_cmp);

    return sorted_hash;
}
