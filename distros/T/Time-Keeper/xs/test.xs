# Doors for the tests only.

MODULE = Time::Keeper    PACKAGE = Time::Keeper

# The version of Zone's table this was compiled against.
IV
_zone_abi_built()
    CODE:
        RETVAL = TKZ_ABI_VERSION;
    OUTPUT:
        RETVAL

# Whether the table has been looked for yet, without looking.
IV
_zone_abi_resolved()
    CODE:
        RETVAL = tk_zone_table ? 1 : 0;
    OUTPUT:
        RETVAL

# Finds the table, loading Zone if it has to, and gives its version.
IV
_zone_abi_version()
    CODE:
        RETVAL = tk_zone_abi(aTHX)->abi_version;
    OUTPUT:
        RETVAL

# 2**62 + 1 worked out in int64_t and written out by hand, so the answer does
# not depend on the perl's IV or NV holding it.
SV *
_int64_probe()
    PREINIT:
        int64_t v;
        char buf[24];
        char *p;
    CODE:
        v = ((int64_t)1 << 62) + 1;
        p = buf + sizeof buf;
        *--p = '\0';
        do { *--p = (char)('0' + (int)(v % 10)); v /= 10; } while (v);
        RETVAL = newSVpv(p, 0);
    OUTPUT:
        RETVAL

# A value's flags: 1 when its date fields have been worked out, 2 when on
# daylight saving time.
IV
_flags(self)
        SV *self
    CODE:
        RETVAL = tk_value_of(aTHX_ self, "_flags")->flags;
    OUTPUT:
        RETVAL

# The size of a value's bytes, for the tests that forge one.
IV
_value_size()
    CODE:
        RETVAL = sizeof(tk_value);
    OUTPUT:
        RETVAL

# today, as it would be at a given instant in a value's zone: the same
# code today runs, given the instant instead of the clock.
SV *
_today_at(self)
        SV *self
    PREINIT:
        tk_value *v;
        tk_value nv;
    CODE:
        v = tk_value_rw(self, "_today_at");
        tk_value_start_of_day(aTHX_ &nv, v, "_today_at");
        RETVAL = tk_value_new_sv(aTHX_ SvSTASH(SvRV(self)), &nv);
    OUTPUT:
        RETVAL

# Where a value's fields lie in its bytes: (nsec, utoff, zone). A 32-bit
# perl packs the instant into 12 bytes, a 64-bit one into 16.
void
_value_layout()
    PPCODE:
        EXTEND(SP, 3);
        mPUSHi(STRUCT_OFFSET(tk_value, inst) + STRUCT_OFFSET(tk_instant, nsec));
        mPUSHi(STRUCT_OFFSET(tk_value, utoff));
        mPUSHi(STRUCT_OFFSET(tk_value, zone));
