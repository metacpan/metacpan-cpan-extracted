# The two tables this dist is built on, seen from Perl: their versions, and
# a public method that resolves both and reports them.

MODULE = Time::Keeper::Recurrence    PACKAGE = Time::Keeper::Recurrence

IV
_tk_abi_version()
    CODE:
        RETVAL = tkr_tk(aTHX)->abi_version;
    OUTPUT:
        RETVAL

IV
_tkz_abi_version()
    CODE:
        RETVAL = tkr_tkz(aTHX)->abi_version;
    OUTPUT:
        RETVAL

IV
_tk_abi_needed()
    ALIAS:
        _tkz_abi_needed = 1
    CODE:
        RETVAL = ix ? TKR_TKZ_NEEDS : TKR_TK_NEEDS;
    OUTPUT:
        RETVAL

void
abi_versions(class)
        SV *class
    PREINIT:
        IV tk, tkz;
    PPCODE:
        PERL_UNUSED_VAR(class);
        /* both tables first: resolving one runs Perl, which may move the stack SP points into */
        tk = tkr_tk(aTHX)->abi_version;
        tkz = tkr_tkz(aTHX)->abi_version;
        SP = PL_stack_base + ax - 1;   /* the frame's base again, by index: the stack may have moved */
        EXTEND(SP, 2);
        mPUSHi(tk);
        mPUSHi(tkz);
