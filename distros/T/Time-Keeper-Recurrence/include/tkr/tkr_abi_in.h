#ifndef TKR_ABI_IN_H
#define TKR_ABI_IN_H

/* The two tables this dist is built on: Time::Keeper's (values, zones by
 * name, wall clocks) and Time::Keeper::Zone's (the transitions and both
 * readings of a wall time). Time::Keeper's is resolved when the module
 * loads, since every rule makes Time::Keeper values; Zone's the first time
 * a named zone is seen, as the core does, so a program whose rules stay in
 * UTC never loads the zone data.
 *
 * Neither has anything to degrade to, so each of the three ways of not
 * getting a table croaks and says which it was: the module could not be
 * loaded (with perl's reason), it loaded but gave no table, or its table is
 * older than the version this dist calls into.
 *
 * Both tables are const data in their shared objects, the same for every
 * interpreter, so one pointer each serves them all. Calls are written
 * (T->entry)(aTHX_ ...): the parentheses keep a member's name from being
 * read as a function-like macro on a perl built with PERL_IMPLICIT_SYS. */

#define TKR_TK_NEEDS  2   /* time_keeper_abi.h: cal_fields and new_sv_cal are version 2's */
#define TKR_TKZ_NEEDS 2   /* time_keeper_zone_abi.h: resolve_local_all is version 2's */

static const time_keeper_abi *tkr_tk_table = NULL;
static const tkz_abi         *tkr_tkz_table = NULL;

/* The address a module's _abi_ptr gives, or 0, with the load error in *msg
 * (a mortal) when it would not load. The caller's $@ is left as it was. */
static UV
tkr_abi_ptr_of(pTHX_ const char *code, SV **msg)
{
    SV *sv, *err;
    UV ptr = 0;
    *msg = NULL;
    ENTER;
    save_scalar(PL_errgv);
    sv = eval_pv(code, 0);
    err = ERRSV;
    if (err && SvTRUE(err))
        *msg = sv_2mortal(newSVsv(err));
    else if (sv && SvOK(sv))
        ptr = SvUV(sv);
    LEAVE;
    return ptr;
}

static const time_keeper_abi *
tkr_tk(pTHX)
{
    SV *msg;
    UV ptr;
    const time_keeper_abi *t;
    if (tkr_tk_table)
        return tkr_tk_table;
    ptr = tkr_abi_ptr_of(aTHX_ "require Time::Keeper; Time::Keeper::_abi_ptr()", &msg);
    if (msg)
        croak("Time::Keeper::Recurrence needs Time::Keeper 0.05 or later, with its C ABI at version %d or later, "
              "and could not load it: %" SVf, TKR_TK_NEEDS, SVfARG(msg));
    if (!ptr)
        croak("Time::Keeper::Recurrence needs Time::Keeper 0.05 or later, with its C ABI at version %d or later: "
              "the Time::Keeper that loaded has no C ABI table", TKR_TK_NEEDS);
    t = INT2PTR(const time_keeper_abi *, ptr);
    if (t->abi_version < TKR_TK_NEEDS)
        croak("Time::Keeper::Recurrence needs Time::Keeper with its C ABI at version %d or later: "
              "the Time::Keeper that loaded has version %d", TKR_TK_NEEDS, t->abi_version);
    tkr_tk_table = t;
    return t;
}

static const tkz_abi *
tkr_tkz(pTHX)
{
    SV *msg;
    UV ptr;
    const tkz_abi *t;
    if (tkr_tkz_table)
        return tkr_tkz_table;
    ptr = tkr_abi_ptr_of(aTHX_ "require Time::Keeper::Zone; Time::Keeper::Zone::_abi_ptr()", &msg);
    if (msg)
        croak("Time::Keeper::Recurrence needs Time::Keeper::Zone 0.04 or later, with its C ABI at version %d or later, "
              "and could not load it: %" SVf, TKR_TKZ_NEEDS, SVfARG(msg));
    if (!ptr)
        croak("Time::Keeper::Recurrence needs Time::Keeper::Zone 0.04 or later, with its C ABI at version %d or later: "
              "the Time::Keeper::Zone that loaded has no C ABI table", TKR_TKZ_NEEDS);
    t = INT2PTR(const tkz_abi *, ptr);
    if (t->abi_version < TKR_TKZ_NEEDS)
        croak("Time::Keeper::Recurrence needs Time::Keeper::Zone with its C ABI at version %d or later: "
              "the Time::Keeper::Zone that loaded has version %d", TKR_TKZ_NEEDS, t->abi_version);
    tkr_tkz_table = t;
    return t;
}

#endif
