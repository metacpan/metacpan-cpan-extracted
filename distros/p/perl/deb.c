/*    deb.c
 *
 *    Copyright (C) 1991, 1992, 1993, 1994, 1995, 1996, 1998, 1999, 2000, 2001,
 *    2002, 2003, 2004, 2005, 2006, 2007, 2008 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * 'Didst thou think that the eyes of the White Tower were blind?  Nay,
 *  I have seen more than thou knowest, Grey Fool.'        --Denethor
 *
 *     [p.853 of _The Lord of the Rings_, V/vii: "The Pyre of Denethor"]
 */

/*
 * This file contains various utilities for producing debugging output
 * (mainly related to displaying the stack)
 */

#include "EXTERN.h"
#define PERL_IN_DEB_C
#include "perl.h"

#if defined(MULTIPLICITY)
void
Perl_deb_nocontext(const char *pat, ...)
{
#ifdef DEBUGGING
    dTHX;
    va_list args;
    PERL_ARGS_ASSERT_DEB_NOCONTEXT;
    va_start(args, pat);
    vdeb(pat, &args);
    va_end(args);
#else
    PERL_UNUSED_ARG(pat);
#endif /* DEBUGGING */
}
#endif

/*
=for apidoc      deb
=for apidoc_item deb_nocontext
=for apidoc_item vdeb

When perl is compiled with C<-DDEBUGGING>, these each print to STDERR the
information given by the arguments, prefaced by the name of the file containing
the script causing the call, and the line number within that file.

If the C<v> (verbose) debugging option is in effect, the process id is also
printed.

C<deb> and C<deb_nocontext> differ only in that C<deb_nocontext> does not take
a thread context (C<aTHX>) parameter, so is used in situations where the caller
doesn't already have the thread context.

C<vdeb> is the same as C<deb> except C<args> are an encapsulated argument list.

=cut
*/

void
Perl_deb(pTHX_ const char *pat, ...)
{
    va_list args;
    PERL_ARGS_ASSERT_DEB;
    va_start(args, pat);
#ifdef DEBUGGING
    vdeb(pat, &args);
#else
    PERL_UNUSED_CONTEXT;
#endif /* DEBUGGING */
    va_end(args);
}

void
Perl_vdeb(pTHX_ const char *pat, va_list *args)
{
#ifdef DEBUGGING
    const char* const file = PL_curcop ? OutCopFILE(PL_curcop) : "<null>";
    const char* const display_file = file ? file : "<free>";
    line_t line = PL_curcop ? CopLINE(PL_curcop) : NOLINE;
    if (line == NOLINE)
        line = 0;

    PERL_ARGS_ASSERT_VDEB;

    if (DEBUG_v_TEST)
        PerlIO_printf(Perl_debug_log, "(%ld:%s:%" LINE_Tf ")\t",
                      (long)PerlProc_getpid(), display_file, line);
    else
        PerlIO_printf(Perl_debug_log, "(%s:%" LINE_Tf ")\t",
                      display_file, line);
    (void) PerlIO_vprintf(Perl_debug_log, pat, *args);
#else
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(pat);
    PERL_UNUSED_ARG(args);
#endif /* DEBUGGING */
}

I32
Perl_debstackptrs(pTHX)     /* Currently unused in cpan and core */
{
#ifdef DEBUGGING
    PerlIO_printf(Perl_debug_log,
                  "%8" UVxf " %8" UVxf " %8" IVdf " %8" IVdf " %8" IVdf "\n",
                  PTR2UV(PL_curstack), PTR2UV(PL_stack_base),
                  (IV)*PL_markstack_ptr, (IV)(PL_stack_sp-PL_stack_base),
                  (IV)(PL_stack_max-PL_stack_base));
    PerlIO_printf(Perl_debug_log,
                  "%8" UVxf " %8" UVxf " %8" UVuf " %8" UVuf " %8" UVuf "\n",
                  PTR2UV(PL_mainstack), PTR2UV(AvARRAY(PL_curstack)),
                  PTR2UV(PL_mainstack), PTR2UV(AvFILLp(PL_curstack)),
                  PTR2UV(AvMAX(PL_curstack)));
#else
    PERL_UNUSED_CONTEXT;
#endif /* DEBUGGING */
    return 0;
}


/* dump the contents of a particular stack
 * Display stack_base[stack_min+1 .. stack_max],
 * and display the marks whose offsets are contained in addresses
 * PL_markstack[mark_min+1 .. mark_max] and whose values are in the range
 * of the stack values being displayed
 * On PERL_RC_STACK builds, nonrc_base indicates the lowest
 * non-reference-counted stack element (or 0 if none or not such a build).
 * Display a vertical bar at this position.
 *
 * Only displays top 30 max
 */

STATIC void
S_deb_stack_n(pTHX_ SV** stack_base, SSize_t stack_min, SSize_t stack_max,
        SSize_t mark_min, SSize_t mark_max, SSize_t nonrc_base)
{
#ifdef DEBUGGING
    SSize_t i = stack_max - 30;
    const Stack_off_t *markscan = PL_markstack + mark_min;

    PERL_ARGS_ASSERT_DEB_STACK_N;

    if (i < stack_min)
        i = stack_min;
    
    while (++markscan <= PL_markstack + mark_max)
        if (*markscan >= i)
            break;

    if (i > stack_min)
        PerlIO_printf(Perl_debug_log, "... ");

    if (stack_base[0] != &PL_sv_undef || stack_max < 0)
        PerlIO_printf(Perl_debug_log, " [STACK UNDERFLOW!!!]\n");
    do {
        ++i;
        if (markscan <= PL_markstack + mark_max && *markscan < i) {
            do {
                ++markscan;
                (void)PerlIO_putc(Perl_debug_log, '*');
            }
            while (markscan <= PL_markstack + mark_max && *markscan < i);
            PerlIO_printf(Perl_debug_log, "  ");
        }
        if (i > stack_max)
            break;

        PerlIO_printf(Perl_debug_log, "%-4s  ", SvPEEK(stack_base[i]));

        if (nonrc_base && nonrc_base == i + 1)
            PerlIO_printf(Perl_debug_log, "|  ");
    }
    while (1);
    PerlIO_printf(Perl_debug_log, "\n");
#else
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(stack_base);
    PERL_UNUSED_ARG(stack_min);
    PERL_UNUSED_ARG(stack_max);
    PERL_UNUSED_ARG(mark_min);
    PERL_UNUSED_ARG(mark_max);
    PERL_UNUSED_ARG(nonrc_base);
#endif /* DEBUGGING */
}


/*
=for apidoc debstack

Dump the current stack

=cut
*/

I32
Perl_debstack(pTHX)
{
#ifndef SKIP_DEBUGGING
    if (CopSTASH_eq(PL_curcop, PL_debstash) && !DEBUG_J_TEST_)
        return 0;

    PerlIO_printf(Perl_debug_log, "    =>  ");
    S_deb_stack_n(aTHX_ PL_stack_base,
                0,
                PL_stack_sp - PL_stack_base,
                PL_curstackinfo->si_markoff,
                PL_markstack_ptr - PL_markstack,
#  ifdef PERL_RC_STACK
                PL_curstackinfo->si_stack_nonrc_base
#  else
                0
#  endif
    );


#endif /* SKIP_DEBUGGING */
    return 0;
}


#ifdef DEBUGGING
static const char * const si_names[] = {
    "UNKNOWN",
    "UNDEF",
    "MAIN",
    "MAGIC",
    "SORT",
    "SIGNAL",
    "OVERLOAD",
    "DESTROY",
    "WARNHOOK",
    "DIEHOOK",
    "REQUIRE",
    "MULTICALL",
    "REGCOMP",
    "SMARTMATCH",
    "CONSTRUCTOR"
};
#endif

/* display all stacks */


void
Perl_deb_stack_all(pTHX)
{
#ifdef DEBUGGING
    I32 si_ix;
    const PERL_SI *si;

    /* rewind to start of chain */
    si = PL_curstackinfo;
    while (si->si_prev)
        si = si->si_prev;

    si_ix=0;
    for (;;)
    {
        const size_t si_name_ix = si->si_type+1; /* -1 is a valid index */
        const char * const si_name =
            si_name_ix < C_ARRAY_LENGTH(si_names) ?
            si_names[si_name_ix] : "????";
        I32 ix;
        PerlIO_printf(Perl_debug_log, "STACK %" IVdf ": %s%s\n",
                                                (IV)si_ix, si_name,
#  ifdef PERL_RC_STACK
            AvREAL(si->si_stack)
                ? (si->si_stack_nonrc_base ? " (partial real)" : " (real)")
                : ""
#  else
                ""
#  endif
        );

        for (ix=0; ix<=si->si_cxix; ix++) {

            const PERL_CONTEXT * const cx = &(si->si_cxstack[ix]);
            PerlIO_printf(Perl_debug_log,
                    "  CX %" IVdf ": %-6s => ",
                    (IV)ix, PL_block_type[CxTYPE(cx)]
            );
            /* substitution contexts don't save stack pointers etc) */
            if (CxTYPE(cx) == CXt_SUBST)
                PerlIO_printf(Perl_debug_log, "\n");
            else {

                /* Find the current context's stack range by searching
                 * forward for any higher contexts using this stack; failing
                 * that, it will be equal to the size of the stack for old
                 * stacks, or PL_stack_sp for the current stack
                 */

                I32 i, stack_min, stack_max, mark_min, mark_max;
                const PERL_CONTEXT *cx_n = NULL;
                const PERL_SI *si_n;

                /* there's a separate argument stack per SI, so only
                 * search this one */

                for (i=ix+1; i<=si->si_cxix; i++) {
                    const PERL_CONTEXT *this_cx = &(si->si_cxstack[i]);
                    if (CxTYPE(this_cx) == CXt_SUBST)
                        continue;
                    cx_n = this_cx;
                    break;
                }

                stack_min = cx->blk_oldsp;

                if (cx_n) {
                    stack_max = cx_n->blk_oldsp;
                }
                else if (si == PL_curstackinfo) {
                    stack_max = PL_stack_sp - AvARRAY(si->si_stack);
                }
                else {
                    stack_max = AvFILLp(si->si_stack);
                }

                /* for the markstack, there's only one stack shared
                 * between all SIs */

                si_n = si;
                i = ix;
                cx_n = NULL;
                for (;;) {
                    i++;
                    if (i > si_n->si_cxix) {
                        if (si_n == PL_curstackinfo)
                            break;
                        else {
                            si_n = si_n->si_next;
                            i = 0;
                        }
                    }
                    if (CxTYPE(&(si_n->si_cxstack[i])) == CXt_SUBST)
                        continue;
                    if (si_n->si_cxix >= 0)
                        cx_n = &(si_n->si_cxstack[i]);
                    else
                        cx_n = NULL;
                    break;
                }

                mark_min  = cx->blk_oldmarksp;
                if (cx_n) {
                    mark_max  = cx_n->blk_oldmarksp;
                }
                else {
                    mark_max = PL_markstack_ptr - PL_markstack;
                }

                S_deb_stack_n(aTHX_ AvARRAY(si->si_stack),
                        stack_min, stack_max, mark_min, mark_max,
#  ifdef PERL_RC_STACK
                        si->si_stack_nonrc_base
#  else
                        0
#  endif
                );

                if (CxTYPE(cx) == CXt_EVAL || CxTYPE(cx) == CXt_SUB
                        || CxTYPE(cx) == CXt_FORMAT)
                {
                    const OP * const retop = cx->blk_sub.retop;

                    PerlIO_printf(Perl_debug_log, "  retop=%s\n",
                            retop ? OP_NAME(retop) : "(null)"
                    );
                }
            }
        } /* next context */


        if (si == PL_curstackinfo)
            break;
        si = si->si_next;
        si_ix++;
        if (!si)
            break; /* shouldn't happen, but just in case.. */
    } /* next stackinfo */

    PerlIO_printf(Perl_debug_log, "\n");
#else
    PERL_UNUSED_CONTEXT;
#endif /* DEBUGGING */
}

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
