#ifndef TKZ_ABI_IMPL_H
#define TKZ_ABI_IMPL_H

/* Zone ids and transition times are 64-bit on every perl, 32-bit ones
 * included: refuse to build where int64_t is not eight bytes. */
typedef char tkz_int64_is_eight_bytes[sizeof(int64_t) == 8 ? 1 : -1];

static const char *tkz_abi_tzdata_version(void) { return TKZ_TZDATA_VERSION; }
static int tkz_abi_zone_count(void) { return TKZ_LOOKUP_COUNT; }

static const tkz_abi TKZ_ABI = {
    TKZ_ABI_VERSION,
    tkz_lookup_name,
    tkz_id_name,
    tkz_id_canonical,
    tkz_id_is_link,
    tkz_offset_at,
    tkz_next_change,
    tkz_resolve_local,
    tkz_local_zone,
    tkz_abi_tzdata_version,
    tkz_abi_zone_count,
    tkz_prev_change,
    tkz_resolve_local_all,
    tkz_standard_offset_at,
    tkz_country_of,
    tkz_windows_name
};

#endif
