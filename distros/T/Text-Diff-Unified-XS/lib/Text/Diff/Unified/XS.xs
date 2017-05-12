#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_newSVpvn_flags
#include "ppport.h"

#include <vector>
#include <string>

#include "diff_helper.hpp"
#include "io_helper.hpp"

/*
 * XXX: fix compiler errors
 * `error: declaration of 'Perl___notused' has a different language linkage`
 */
#ifdef __cplusplus
#define dNOOP (void)0
#else
#define dNOOP extern int Perl___notused(void)
#endif

MODULE = Text::Diff::Unified::XS    PACKAGE = Text::Diff::Unified::XS

PROTOTYPES: DISABLE

void
_diff_by_strings(...)
PROTOTYPE: $$
PPCODE:
{
    std::vector<std::string> lines_a;
    std::vector<std::string> lines_b;

    if (SvROK(ST(0))) {
        const char *data = SvPV_nolen(SvRV(ST(0)));
        split_lines(data, lines_a);
    }

    if (SvROK(ST(1))) {
        const char *data = SvPV_nolen(SvRV(ST(1)));
        split_lines(data, lines_b);
    }

    std::string diff_str = diff_sequence(lines_a, lines_b);
    SV *diff_sv = sv_2mortal(newSVpv(diff_str.c_str(), 0));

    XPUSHs(diff_sv);
    XSRETURN(1);
}

void
_diff_by_files(...)
PROTOTYPE: $$
PPCODE:
{
    std::vector<std::string> lines_a;
    std::vector<std::string> lines_b;

    const char *fname_a = SvPV_nolen(ST(0));
    const char *fname_b = SvPV_nolen(ST(1));

    read_lines(aTHX_ fname_a, lines_a);
    read_lines(aTHX_ fname_b, lines_b);

    std::string diff_str = diff_sequence(lines_a, lines_b);
    SV *diff_sv = sv_2mortal(newSVpv(diff_str.c_str(), 0));

    XPUSHs(diff_sv);
    XSRETURN(1);
}

