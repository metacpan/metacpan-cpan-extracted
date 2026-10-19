#ifndef TKB_ABI_H
#define TKB_ABI_H

/* Time::Keeper's table, found the first time a date is read or written
 * and never before: loading this module does not resolve it.
 *
 * The table is const data in the core's shared object, the same for every
 * interpreter, so one pointer serves them all. */

#if TIME_KEEPER_ABI_VERSION < 2
#error "Time::Keeper::Business needs time_keeper_abi.h at version 2 or later: install Time::Keeper 0.05 or later first"
#endif

/* The version of the core's table whose entries this dist calls: version
 * 2's, for new_sv_cal and from_sv_cal. It rises only when a later entry is
 * called, not with the TIME_KEEPER_ABI_VERSION of the header built against,
 * so a build against a newer core still runs with an older one that has
 * what it calls. */
#define TKB_ABI_NEEDS 2

static const time_keeper_abi *tkb_table = NULL;

static const time_keeper_abi *
tkb_abi(pTHX)
{
    SV *sv, *err, *msg = NULL;
    const time_keeper_abi *t = NULL;

    if (tkb_table)
        return tkb_table;

    /* The caller's $@ is not ours to change. The VALUE eval_pv returns is
     * the pointer, not the top of the stack. */
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
        croak("Time::Keeper::Business needs Time::Keeper 0.05 or later: %" SVf,
              SVfARG(msg ? msg : sv_2mortal(newSVpvs("it did not load\n"))));
    if (t->abi_version < TKB_ABI_NEEDS) {
        SV *ver = get_sv("Time::Keeper::VERSION", 0);
        croak("Time::Keeper::Business needs Time::Keeper 0.05 or later (have %" SVf
              "): its table is at version %d and version %d is needed",
              SVfARG(ver && SvOK(ver) ? ver : sv_2mortal(newSVpvs("an older one"))),
              t->abi_version, TKB_ABI_NEEDS);
    }

    tkb_table = t;
    return t;
}

/* Every entry is called through the parentheses: XSUB.h defines
 * function-like macros for a number of ordinary names on a perl built with
 * PERL_IMPLICIT_SYS, and a member's name must not be read as one. */
#define TKB(entry) (tkb_abi(aTHX)->entry)

#endif
