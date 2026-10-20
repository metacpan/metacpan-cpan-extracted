# The XS of Time::Keeper::Natural, Phase 02: the table found, the caches
# made, and CLONE giving a thread its own. Later phases add their fragments.

MODULE = Time::Keeper::Natural    PACKAGE = Time::Keeper::Natural

IV
_abi_version()
    CODE:
        RETVAL = TKN_TK ? TKN_TK->abi_version : 0;
    OUTPUT:
        RETVAL

IV
_cache_generation()
    CODE:
        {
            dMY_CXT;
            RETVAL = MY_CXT.generation;
        }
    OUTPUT:
        RETVAL

IV
_cache_size()
    CODE:
        {
            dMY_CXT;
            RETVAL = HvUSEDKEYS(MY_CXT.lexicons) + HvUSEDKEYS(MY_CXT.words) + HvUSEDKEYS(MY_CXT.numbers);
        }
    OUTPUT:
        RETVAL

void
CLONE(...)
    CODE:
        PERL_UNUSED_VAR(items);
        {
            IV gen;
            {
                dMY_CXT;
                gen = MY_CXT.generation;
            }
            {
                MY_CXT_CLONE;
                tkn_cxt_init(aTHX_ &MY_CXT);
                MY_CXT.generation = gen + 1;
            }
        }
