# The C ABI's Perl-visible ends: the table's address, its version, and the
# self-test that calls every entry as a consumer would.

MODULE = Time::Keeper::Recurrence    PACKAGE = Time::Keeper::Recurrence

# Unsigned, not IV: a 32-bit perl may map the table above 0x7fffffff.
UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(&TKR_ABI);
    OUTPUT:
        RETVAL

IV
_abi_version()
    CODE:
        RETVAL = TKR_ABI.abi_version;
    OUTPUT:
        RETVAL

void
_abi_selftest(ptr)
        UV ptr
    PREINIT:
        SV *made = NULL;
        int step;
    PPCODE:
        step = tkr_abi_selftest(aTHX_ INT2PTR(const time_keeper_recurrence_abi *, ptr), &made);
        SP = PL_stack_base + ax - 1;
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(step)));
        PUSHs(made ? sv_2mortal(made) : &PL_sv_undef);
