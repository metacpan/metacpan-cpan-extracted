# The C ABI's Perl-visible ends: the table's address and its version.

MODULE = Time::Keeper::Zone    PACKAGE = Time::Keeper::Zone

# Unsigned, not IV: a 32-bit perl may map the table above 0x7fffffff.
UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(&TKZ_ABI);
    OUTPUT:
        RETVAL

IV
_abi_version()
    CODE:
        RETVAL = TKZ_ABI.abi_version;
    OUTPUT:
        RETVAL
