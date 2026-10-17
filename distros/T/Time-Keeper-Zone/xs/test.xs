# Doors for the tests only.

MODULE = Time::Keeper::Zone    PACKAGE = Time::Keeper::Zone

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
