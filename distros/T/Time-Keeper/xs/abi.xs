# The C ABI's Perl-visible ends: the table's address, its version, and the
# self-test that calls every entry as a consumer would.

MODULE = Time::Keeper    PACKAGE = Time::Keeper

# Unsigned, not IV: a 32-bit perl may map the table above 0x7fffffff.
UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(&TK_ABI);
    OUTPUT:
        RETVAL

IV
_abi_version()
    CODE:
        RETVAL = TK_ABI.abi_version;
    OUTPUT:
        RETVAL

void
_abi_selftest(ptr)
        UV ptr
    PREINIT:
        SV *made = NULL;
        int step;
    PPCODE:
        step = tk_abi_selftest(aTHX_ INT2PTR(const time_keeper_abi *, ptr), &made);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(step)));
        PUSHs(made ? sv_2mortal(made) : &PL_sv_undef);
