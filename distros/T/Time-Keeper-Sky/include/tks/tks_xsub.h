#ifndef TKS_XSUB_H
#define TKS_XSUB_H

/* One compiled XSUB under more than one package: a class whose methods are
 * another's (Time::Keeper::Sun's are Time::Keeper::Sky's) gets the same C
 * functions installed under its own names, an ALIAS's index with them, and
 * its @ISA set here; nothing is aliased from Perl. */

/* Each method in names (NULL-terminated), defined as an XSUB in package
 * from, installed in package to as the same XSUB. */
static void
tks_xsubs_share(pTHX_ const char *from, const char *to, const char *const *names)
{
    int i;
    for (i = 0; names[i]; i++) {
        char src[128], dst[128];
        CV *cv, *copy;
        snprintf(src, sizeof src, "%s::%s", from, names[i]);
        snprintf(dst, sizeof dst, "%s::%s", to, names[i]);
        cv = get_cv(src, 0);
        if (!cv || !CvISXSUB(cv))
            croak("%s is not an XSUB to share", src);
        copy = newXS(dst, CvXSUB(cv), (char *)__FILE__);
        CvXSUBANY(copy).any_i32 = CvXSUBANY(cv).any_i32;
    }
}

/* A package's @ISA, as one parent. */
static void
tks_isa(pTHX_ const char *child, const char *parent)
{
    char name[128];
    AV *isa;
    snprintf(name, sizeof name, "%s::ISA", child);
    isa = get_av(name, GV_ADD);
    av_clear(isa);
    av_push(isa, newSVpv(parent, 0));
}

#endif
