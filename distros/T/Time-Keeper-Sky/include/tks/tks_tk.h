#ifndef TKS_TK_H
#define TKS_TK_H

/* Time::Keeper's table, found the first time a method needs it and never
 * before: loading Time::Keeper::Sun does not load Time::Keeper.
 *
 * The table is const data in Time::Keeper's shared object, the same for
 * every interpreter, so one pointer serves them all. */

/* The version of Time::Keeper's table whose entries this dist calls:
 * version 1's. It rises only when a method calls a later entry, not with
 * the TIME_KEEPER_ABI_VERSION of the header it was built against, so a
 * dist built against a newer Time::Keeper still runs with an older one. */
#define TKS_TK_ABI_NEEDS 1

static const time_keeper_abi *tks_tk_table = NULL;

static const time_keeper_abi *
tks_tk(pTHX)
{
    SV *sv, *err, *msg = NULL;
    const time_keeper_abi *t = NULL;

    if (tks_tk_table)
        return tks_tk_table;

    /* The caller's $@ is not ours to change. */
    ENTER;
    save_scalar(PL_errgv);
    sv = eval_pv("require Time::Keeper; Time::Keeper::_abi_ptr()", 0);
    err = ERRSV;
    if (err && SvTRUE(err))
        msg = sv_2mortal(newSVsv(err));
    else if (sv && SvOK(sv))
        t = INT2PTR(const time_keeper_abi *, SvUV(sv));
    LEAVE;

    if (!t)
        croak("Time::Keeper::Sun needs Time::Keeper: %" SVf,
              SVfARG(msg ? msg : sv_2mortal(newSVpvs("it did not load\n"))));
    if (t->abi_version < TKS_TK_ABI_NEEDS)
        croak("Time::Keeper::Sun needs Time::Keeper's table at version %d or later, and found %d",
              TKS_TK_ABI_NEEDS, t->abi_version);

    tks_tk_table = t;
    return t;
}

#endif
