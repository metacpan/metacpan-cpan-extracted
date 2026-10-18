#ifndef TK_ZONE_H
#define TK_ZONE_H

/* Time::Keeper::Zone's table, found the first time a named zone is asked
 * for and never before: a program that stays in UTC or a fixed offset does
 * not load the zone data at all.
 *
 * The table is const data in Zone's shared object, the same for every
 * interpreter, so one pointer serves them all. */

/* The version of Zone's table whose entries the core calls: version 1's
 * ten. It rises only when the core calls a later entry, not with the
 * TKZ_ABI_VERSION of the header it was built against, so a core built
 * against a newer Zone still runs with an older one. */
#define TK_ZONE_ABI_NEEDS 1

static const tkz_abi *tk_zone_table = NULL;

static const tkz_abi *
tk_zone_abi(pTHX)
{
    SV *sv, *err, *msg = NULL;
    const tkz_abi *t = NULL;

    if (tk_zone_table)
        return tk_zone_table;

    /* The caller's $@ is not ours to change. */
    ENTER;
    save_scalar(PL_errgv);
    sv = eval_pv("require Time::Keeper::Zone; Time::Keeper::Zone::_abi_ptr()", 0);
    err = ERRSV;
    if (err && SvTRUE(err))
        msg = sv_2mortal(newSVsv(err));
    else if (sv && SvOK(sv))
        t = INT2PTR(const tkz_abi *, SvUV(sv));
    LEAVE;

    if (!t)
        croak("Time::Keeper needs Time::Keeper::Zone for a named time zone: %" SVf,
              SVfARG(msg ? msg : sv_2mortal(newSVpvs("it did not load\n"))));
    if (t->abi_version < TK_ZONE_ABI_NEEDS)
        croak("Time::Keeper needs Time::Keeper::Zone's table at version %d or later, and found %d",
              TK_ZONE_ABI_NEEDS, t->abi_version);

    tk_zone_table = t;
    return t;
}

/* The table, for a method that calls one of version 2's entries: dies
 * naming the method and the Zone installed when the table is older. */
static const tkz_abi *
tk_zone_abi_v2(pTHX_ const char *what)
{
    const tkz_abi *t = tk_zone_abi(aTHX);
    if (t->abi_version < 2) {
        SV *ver = get_sv("Time::Keeper::Zone::VERSION", 0);
        croak("%s needs Time::Keeper::Zone 0.03 or later (have %" SVf ")", what,
              SVfARG(ver && SvOK(ver) ? ver : sv_2mortal(newSVpvs("an older one"))));
    }
    return t;
}

#endif
